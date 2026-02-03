/// ============================================================================
/// CHECKIN SERVICE - Serviço de Check-in
/// ============================================================================
///
/// Gerencia a lógica de check-in de leitura:
/// - Validação de check-in único por dia
/// - Cálculo de streak
/// - Persistência no Firestore
///
/// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../core/services/storage_service.dart';
import '../models/checkin_model.dart';

/// Exceção customizada para erros de check-in.
class CheckinException implements Exception {
  final String message;
  final String? code;

  const CheckinException(this.message, {this.code});

  @override
  String toString() => 'CheckinException: $message';
}

/// Serviço de check-in de leitura.
class CheckinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // Formato de data usado para comparação (YYYY-MM-DD)
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Realiza um check-in de leitura.
  ///
  /// [userId] - ID do usuário
  /// [userName] - Nome do usuário (para desnormalização)
  /// [title] - Título do check-in
  /// [description] - Descrição opcional
  /// [imageFile] - Arquivo da imagem (mobile)
  /// [imageBytes] - Bytes da imagem (web)
  ///
  /// Retorna o [CheckinModel] criado.
  Future<CheckinModel> performCheckin({
    required String userId,
    required String userName,
    required String title,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    // Validações
    if (title.trim().isEmpty) {
      throw const CheckinException('O título é obrigatório');
    }

    // Foto agora é opcional
    // if (imageFile == null && imageBytes == null) {
    //   throw const CheckinException('A foto é obrigatória');
    // }

    // Data de hoje (formato YYYY-MM-DD)
    final today = _dateFormat.format(DateTime.now());

    // Busca dados do usuário
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw const CheckinException('Usuário não encontrado');
    }

    final userData = userDoc.data()!;
    final lastCheckinDate = userData['lastCheckinDate'] as String?;

    // Verifica se já fez check-in hoje
    if (lastCheckinDate == today) {
      throw const CheckinException(
        'Você já registrou sua leitura hoje!',
        code: 'already-checked-in',
      );
    }

    // Faz upload da imagem (se houver)
    String? imageUrl;
    if (imageFile != null || imageBytes != null) {
      try {
        imageUrl = await _storageService.uploadCheckinImage(
          userId: userId,
          imageFile: imageFile,
          imageBytes: imageBytes,
        );
      } catch (e) {
        throw CheckinException('Erro ao enviar imagem: $e');
      }
    }

    // Calcula o novo streak
    final currentStreak = userData['currentStreak'] as int? ?? 0;
    final maxStreak = userData['maxStreak'] as int? ?? 0;
    final totalCheckins = userData['totalCheckins'] as int? ?? 0;

    int newStreak;
    if (lastCheckinDate == null) {
      // Primeiro check-in
      newStreak = 1;
    } else {
      // Verifica se fez check-in ontem
      final yesterday = _dateFormat.format(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      if (lastCheckinDate == yesterday) {
        // Mantém a sequência
        newStreak = currentStreak + 1;
      } else {
        // Perdeu a sequência, mas não zera (apenas para de crescer)
        // Começa nova sequência
        newStreak = 1;
      }
    }

    final newMaxStreak = newStreak > maxStreak ? newStreak : maxStreak;
    final newTotalCheckins = totalCheckins + 1;

    // Cria o documento de check-in
    final checkinData = {
      'userId': userId,
      'userName': userName,
      'title': title.trim(),
      'description': description?.trim(),
      'imageUrl': imageUrl,
      'date': today,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Salva no Firestore usando batch
    final batch = _firestore.batch();

    // Adiciona check-in
    final checkinRef = _firestore.collection('checkins').doc();
    batch.set(checkinRef, checkinData);

    // Atualiza dados do usuário
    batch.update(_firestore.collection('users').doc(userId), {
      'currentStreak': newStreak,
      'maxStreak': newMaxStreak,
      'totalCheckins': newTotalCheckins,
      'lastCheckinDate': today,
    });

    await batch.commit();

    return CheckinModel(
      id: checkinRef.id,
      userId: userId,
      userName: userName,
      title: title.trim(),
      description: description?.trim(),
      imageUrl: imageUrl,
      date: today,
      createdAt: DateTime.now(),
    );
  }

  /// Verifica se o usuário já fez check-in hoje.
  Future<bool> hasCheckedInToday(String userId) async {
    final today = _dateFormat.format(DateTime.now());

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;

    final lastCheckinDate = userDoc.data()?['lastCheckinDate'] as String?;
    return lastCheckinDate == today;
  }

  /// Busca os check-ins recentes de todos os usuários.
  Future<List<CheckinModel>> getRecentCheckins({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('checkins')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => CheckinModel.fromFirestore(doc)).toList();
  }

  /// Busca os check-ins de um usuário específico.
  Future<List<CheckinModel>> getUserCheckins(
    String userId, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => CheckinModel.fromFirestore(doc)).toList();
  }

  /// Busca os dados de streak do usuário.
  Future<Map<String, dynamic>> getUserStreakData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return {'currentStreak': 0, 'maxStreak': 0, 'totalCheckins': 0};
    }

    final data = userDoc.data()!;
    return {
      'currentStreak': data['currentStreak'] ?? 0,
      'maxStreak': data['maxStreak'] ?? 0,
      'totalCheckins': data['totalCheckins'] ?? 0,
      'lastCheckinDate': data['lastCheckinDate'],
    };
  }
}
