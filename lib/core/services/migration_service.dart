/// ============================================================================
/// MIGRATION SERVICE - Migração de Dados Legados
/// ============================================================================
///
/// Serviço para migrar dados existentes (sem grupo) para o novo schema.
/// Executa uma única vez no primeiro start da app atualizada.
///
/// Etapas:
/// 1. Cria grupo "Restauração" com todos os users atuais
/// 2. Adiciona groupId a todos os check-ins existentes
/// 3. Adiciona groupId a todas as mensagens existentes
/// 4. Define activeGroupId para todos os users
///
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Adicionado para verificar auth
import 'dart:math';

/// Serviço de migração de dados legados.
class MigrationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth; // Adicionado

  /// Chave para controlar se a migração já foi executada.
  static const String _migrationKey = 'migration_v2_groups';

  MigrationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Verifica se precisa rodar a migração e executa se necessário.
  Future<void> runIfNeeded() async {
    try {
      // Só tenta migrar se houver um usuário autenticado (devido às regras do Firestore)
      if (_auth.currentUser == null) {
        print('ℹ️ Migração aguardando login do usuário para ter permissões.');
        return;
      }

      // Verifica se já migrou consultando a collection de metadata
      final migrationDoc = await _firestore
          .collection('app_metadata')
          .doc(_migrationKey)
          .get();

      if (migrationDoc.exists) {
        // Já migrado
        return;
      }

      await _runMigration();
    } catch (e) {
      // Se houver erro, loga mas não impede o app de funcionar
      print('⚠️ Erro na migração: $e');
    }
  }

  /// Executa a migração completa.
  Future<void> _runMigration() async {
    print('🔄 Iniciando migração para sistema de grupos...');

    // 1. Buscar todos os usuários
    final usersSnapshot = await _firestore.collection('users').get();
    final userIds = usersSnapshot.docs.map((d) => d.id).toList();

    if (userIds.isEmpty) {
      print('ℹ️ Nenhum usuário encontrado. Migração ignorada.');
      return;
    }

    // 2. Criar grupo "Restauração" com todos os users
    final groupId = await _createDefaultGroup(userIds);

    // 3. Adicionar groupId a todos os check-ins existentes
    await _migrateCheckins(groupId);

    // 4. Adicionar groupId a todas as mensagens existentes
    await _migrateMessages(groupId);

    // 5. Definir activeGroupId para todos os users
    await _updateUsersActiveGroup(userIds, groupId);

    // 6. Marcar migração como concluída
    await _firestore.collection('app_metadata').doc(_migrationKey).set({
      'completedAt': FieldValue.serverTimestamp(),
      'defaultGroupId': groupId,
      'migratedUsers': userIds.length,
    });

    print('✅ Migração concluída! Grupo padrão: $groupId');
  }

  /// Cria o grupo padrão "Restauração".
  Future<String> _createDefaultGroup(List<String> memberIds) async {
    final now = DateTime.now();
    final inviteCode = _generateInviteCode();

    // Duração padrão: 365 dias (retroativo)
    final startDate = now.subtract(const Duration(days: 30));
    final endDate = startDate.add(const Duration(days: 365));

    final groupDoc = await _firestore.collection('groups').add({
      'name': 'Restauração',
      'description':
          'Grupo original do desafio de leitura. Migrado automaticamente.',
      'createdBy': memberIds.first, // O primeiro user vira admin
      'createdAt': Timestamp.fromDate(now),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'durationDays': 365,
      'inviteCode': inviteCode,
      'memberIds': memberIds,
      'memberCount': memberIds.length,
    });

    print('  📋 Grupo "Restauração" criado: ${groupDoc.id}');
    return groupDoc.id;
  }

  /// Migra check-ins existentes adicionando groupId.
  Future<void> _migrateCheckins(String groupId) async {
    final checkinsSnapshot = await _firestore
        .collection('checkins')
        .where('groupId', isNull: true) // Apenas os que não têm groupId
        .get();

    if (checkinsSnapshot.docs.isEmpty) {
      // Tenta sem filtro — Firestore pode não suportar isNull em todos os SDKs
      final allCheckins = await _firestore.collection('checkins').get();
      int count = 0;

      final batch = _firestore.batch();
      for (final doc in allCheckins.docs) {
        if (doc.data()['groupId'] == null) {
          batch.update(doc.reference, {'groupId': groupId});
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
      }
      print('  ✅ $count check-ins migrados');
      return;
    }

    final batch = _firestore.batch();
    for (final doc in checkinsSnapshot.docs) {
      batch.update(doc.reference, {'groupId': groupId});
    }
    await batch.commit();
    print('  ✅ ${checkinsSnapshot.docs.length} check-ins migrados');
  }

  /// Migra mensagens existentes adicionando groupId.
  Future<void> _migrateMessages(String groupId) async {
    final allMessages = await _firestore.collection('messages').get();
    int count = 0;

    final batch = _firestore.batch();
    for (final doc in allMessages.docs) {
      if (doc.data()['groupId'] == null) {
        batch.update(doc.reference, {'groupId': groupId});
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
    print('  ✅ $count mensagens migradas');
  }

  /// Atualiza o activeGroupId de todos os users.
  Future<void> _updateUsersActiveGroup(
    List<String> userIds,
    String groupId,
  ) async {
    final batch = _firestore.batch();
    for (final userId in userIds) {
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {'activeGroupId': groupId});
    }
    await batch.commit();
    print('  ✅ ${userIds.length} usuários atualizados com activeGroupId');
  }

  /// Gera um código de convite aleatório.
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = List.generate(
      4,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return 'ATLAS-$code';
  }
}
