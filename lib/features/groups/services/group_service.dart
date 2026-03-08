/// ============================================================================
/// GROUP SERVICE - Serviço de Grupos/Desafios
/// ============================================================================
///
/// Gerencia operações CRUD de grupos no Firestore.
///
/// Funcionalidades:
/// - Criar grupo com duração em dias
/// - Gerar código de convite único
/// - Entrar em grupo via código
/// - Listar grupos do usuário
/// - Buscar scores (total de check-ins por membro)
/// - Sair/remover membros
///
/// ============================================================================

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

/// Exceção customizada para erros de grupo.
class GroupException implements Exception {
  final String message;
  final String? code;

  const GroupException(this.message, {this.code});

  @override
  String toString() => 'GroupException: $message';
}

/// Serviço para gerenciar grupos/desafios.
class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Coleção de grupos.
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  // ============================================================
  // CRIAÇÃO E ENTRADA
  // ============================================================

  /// Cria um novo grupo/desafio.
  ///
  /// [name] - Nome do grupo
  /// [description] - Descrição opcional
  /// [durationDays] - Duração do desafio em dias
  /// [creatorId] - ID do criador
  ///
  /// Retorna o [GroupModel] criado.
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required int durationDays,
    required String creatorId,
  }) async {
    if (name.trim().isEmpty) {
      throw const GroupException('O nome do grupo é obrigatório');
    }
    if (durationDays < 1) {
      throw const GroupException('A duração deve ser de pelo menos 1 dia');
    }
    if (durationDays > 365) {
      throw const GroupException('A duração máxima é de 365 dias');
    }

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = startDate.add(Duration(days: durationDays));
    final inviteCode = _generateInviteCode();

    final docRef = _groupsCollection.doc();

    final groupData = {
      'name': name.trim(),
      'description': description?.trim(),
      'imageUrl': null,
      'createdBy': creatorId,
      'createdAt': Timestamp.fromDate(now),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'durationDays': durationDays,
      'inviteCode': inviteCode,
      'memberIds': [creatorId],
      'memberCount': 1,
    };

    await docRef.set(groupData);

    // Atualiza o activeGroupId do criador
    await _firestore.collection('users').doc(creatorId).update({
      'activeGroupId': docRef.id,
    });

    return GroupModel(
      id: docRef.id,
      name: name.trim(),
      description: description?.trim(),
      createdBy: creatorId,
      createdAt: now,
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      inviteCode: inviteCode,
      memberIds: [creatorId],
      memberCount: 1,
    );
  }

  /// Entra em um grupo pelo código de convite.
  ///
  /// Retorna o [GroupModel] do grupo.
  Future<GroupModel> joinGroupByCode({
    required String inviteCode,
    required String userId,
  }) async {
    if (inviteCode.trim().isEmpty) {
      throw const GroupException('O código de convite é obrigatório');
    }

    // Busca grupo pelo código
    final snapshot = await _groupsCollection
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw const GroupException(
        'Código de convite inválido',
        code: 'invalid-code',
      );
    }

    final doc = snapshot.docs.first;
    final group = GroupModel.fromFirestore(doc);

    // Verifica se já é membro
    if (group.memberIds.contains(userId)) {
      throw const GroupException(
        'Você já é membro deste grupo',
        code: 'already-member',
      );
    }

    // Adiciona membro
    await _groupsCollection.doc(group.id).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberCount': FieldValue.increment(1),
    });

    // Atualiza o activeGroupId do usuário
    await _firestore.collection('users').doc(userId).update({
      'activeGroupId': group.id,
    });

    return group.copyWith(
      memberIds: [...group.memberIds, userId],
      memberCount: group.memberCount + 1,
    );
  }

  /// Busca um grupo pelo código de convite (preview, sem entrar).
  Future<GroupModel?> getGroupByCode(String inviteCode) async {
    if (inviteCode.trim().isEmpty) return null;

    final snapshot = await _groupsCollection
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return GroupModel.fromFirestore(snapshot.docs.first);
  }

  // ============================================================
  // LEITURA
  // ============================================================

  /// Busca um grupo por ID.
  Future<GroupModel?> getGroupById(String groupId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    if (!doc.exists) return null;
    return GroupModel.fromFirestore(doc);
  }

  /// Lista grupos do usuário.
  Future<List<GroupModel>> getUserGroups(String userId) async {
    final snapshot = await _groupsCollection
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
  }

  /// Stream de grupos do usuário (tempo real).
  Stream<List<GroupModel>> watchUserGroups(String userId) {
    return _groupsCollection
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ============================================================
  // SCORES / RANKING
  // ============================================================

  /// Busca os scores (total de check-ins) de cada membro no grupo.
  ///
  /// Retorna uma lista de mapas com {userId, userName, totalCheckins}.
  Future<List<Map<String, dynamic>>> getMemberScores(String groupId) async {
    final group = await getGroupById(groupId);
    if (group == null) return [];

    // Busca todos os check-ins do grupo no período
    final checkinsSnapshot = await _firestore
        .collection('checkins')
        .where('groupId', isEqualTo: groupId)
        .get();

    // Conta check-ins por usuário
    final Map<String, int> scoreCounts = {};
    final Map<String, String> userNames = {};

    for (final doc in checkinsSnapshot.docs) {
      final data = doc.data();
      final uId = data['userId'] as String? ?? '';
      final uName = data['userName'] as String? ?? 'Usuário';

      scoreCounts[uId] = (scoreCounts[uId] ?? 0) + 1;
      userNames[uId] = uName;
    }

    // Constroi lista ordenada por score
    final scores = group.memberIds.map((memberId) {
      return {
        'userId': memberId,
        'userName': userNames[memberId] ?? 'Usuário',
        'totalCheckins': scoreCounts[memberId] ?? 0,
      };
    }).toList();

    scores.sort(
      (a, b) =>
          (b['totalCheckins'] as int).compareTo(a['totalCheckins'] as int),
    );

    return scores;
  }

  // ============================================================
  // GERENCIAMENTO
  // ============================================================

  /// Remove o usuário de um grupo.
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    await _groupsCollection.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
    });

    // Se o activeGroupId do user era este grupo, limpa
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data()?['activeGroupId'] == groupId) {
      await _firestore.collection('users').doc(userId).update({
        'activeGroupId': null,
      });
    }
  }

  /// Admin remove um membro do grupo.
  Future<void> removeMember({
    required String groupId,
    required String memberId,
    required String adminId,
  }) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw const GroupException('Grupo não encontrado');
    }
    if (group.createdBy != adminId) {
      throw const GroupException('Apenas o criador pode remover membros');
    }
    if (memberId == adminId) {
      throw const GroupException('Você não pode remover a si mesmo');
    }

    await leaveGroup(groupId: groupId, userId: memberId);
  }

  /// Gera um novo código de convite para o grupo.
  Future<String> regenerateInviteCode(String groupId) async {
    final newCode = _generateInviteCode();
    await _groupsCollection.doc(groupId).update({'inviteCode': newCode});
    return newCode;
  }

  /// Atualiza o grupo ativo do usuário.
  Future<void> setActiveGroup({
    required String userId,
    required String groupId,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'activeGroupId': groupId,
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Gera um código de convite único no formato ATLAS-XXXX.
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final code = List.generate(
      4,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return 'ATLAS-$code';
  }
}
