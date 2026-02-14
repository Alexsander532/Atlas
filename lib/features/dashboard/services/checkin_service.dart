/// ============================================================================
/// CHECKIN SERVICE - Serviço de Check-in
/// ============================================================================
///
/// Gerencia a lógica de check-in de leitura:
/// - Validação de check-in único por dia POR GRUPO
/// - Pontuação simples: 1 check-in/dia = 1 ponto
/// - Validação de desafio ativo (endDate)
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
  /// [groupId] - ID do grupo/desafio
  ///
  /// Retorna o [CheckinModel] criado.
  Future<CheckinModel> performCheckin({
    required String userId,
    required String userName,
    required String title,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
    required String groupId,
  }) async {
    // Validações
    if (title.trim().isEmpty) {
      throw const CheckinException('O título é obrigatório');
    }

    if (groupId.isEmpty) {
      throw const CheckinException('Grupo inválido');
    }

    // Verifica se o desafio ainda está ativo
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) {
      throw const CheckinException('Grupo não encontrado');
    }

    final groupData = groupDoc.data()!;
    final endDate = (groupData['endDate'] as Timestamp).toDate();
    final endOfDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );
    if (DateTime.now().isAfter(endOfDay)) {
      throw const CheckinException(
        'Este desafio já foi encerrado!',
        code: 'challenge-ended',
      );
    }

    // Data de hoje (formato YYYY-MM-DD)
    final today = _dateFormat.format(DateTime.now());

    // Verifica se já fez check-in hoje NESTE GRUPO
    final existingCheckin = await _firestore
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('groupId', isEqualTo: groupId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    if (existingCheckin.docs.isNotEmpty) {
      throw const CheckinException(
        'Você já registrou sua leitura hoje neste grupo!',
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

    // Cria o documento de check-in
    final checkinData = {
      'userId': userId,
      'userName': userName,
      'title': title.trim(),
      'description': description?.trim(),
      'imageUrl': imageUrl,
      'date': today,
      'createdAt': FieldValue.serverTimestamp(),
      'groupId': groupId,
    };

    // Salva no Firestore
    final checkinRef = _firestore.collection('checkins').doc();
    await checkinRef.set(checkinData);

    return CheckinModel(
      id: checkinRef.id,
      userId: userId,
      userName: userName,
      title: title.trim(),
      description: description?.trim(),
      imageUrl: imageUrl,
      date: today,
      createdAt: DateTime.now(),
      groupId: groupId,
    );
  }

  /// Verifica se o usuário já fez check-in hoje neste grupo.
  Future<bool> hasCheckedInToday(
    String userId, {
    required String groupId,
  }) async {
    final today = _dateFormat.format(DateTime.now());

    final snapshot = await _firestore
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('groupId', isEqualTo: groupId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Busca os check-ins recentes de todos os usuários de um grupo.
  Future<List<CheckinModel>> getRecentCheckins({
    int limit = 20,
    required String groupId,
  }) async {
    final snapshot = await _firestore
        .collection('checkins')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => CheckinModel.fromFirestore(doc)).toList();
  }

  /// Busca os check-ins de um usuário específico em um grupo.
  Future<List<CheckinModel>> getUserCheckins(
    String userId, {
    int limit = 50,
    required String groupId,
  }) async {
    final snapshot = await _firestore
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => CheckinModel.fromFirestore(doc)).toList();
  }

  /// Busca o total de check-ins de um usuário em um grupo (pontuação).
  Future<int> getUserScore(String userId, {required String groupId}) async {
    final snapshot = await _firestore
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('groupId', isEqualTo: groupId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Busca os check-ins de um mês específico.
  ///
  /// [year] - Ano (ex: 2025)
  /// [month] - Mês (1-12)
  /// [userId] - Se informado, filtra apenas os check-ins deste usuário.
  /// [groupId] - Filtra por grupo.
  Future<List<CheckinModel>> getCheckinsByMonth(
    int year,
    int month, {
    String? userId,
    required String groupId,
  }) async {
    // Formato: YYYY-MM (para fazer query por prefixo)
    final monthPrefix = '$year-${month.toString().padLeft(2, '0')}';

    Query<Map<String, dynamic>> query = _firestore
        .collection('checkins')
        .where('groupId', isEqualTo: groupId)
        .where('date', isGreaterThanOrEqualTo: '$monthPrefix-01')
        .where('date', isLessThanOrEqualTo: '$monthPrefix-31')
        .orderBy('date', descending: true);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => CheckinModel.fromFirestore(doc)).toList();
  }

  /// Retorna um mapa de check-ins por data.
  ///
  /// Chave: data no formato YYYY-MM-DD
  /// Valor: CheckinModel
  Future<Map<String, CheckinModel>> getCheckinMapByMonth(
    int year,
    int month, {
    String? userId,
    required String groupId,
  }) async {
    final checkins = await getCheckinsByMonth(
      year,
      month,
      userId: userId,
      groupId: groupId,
    );
    final map = <String, CheckinModel>{};
    for (final checkin in checkins) {
      // Se houver múltiplos no mesmo dia, pega o primeiro (mais recente)
      if (!map.containsKey(checkin.date)) {
        map[checkin.date] = checkin;
      }
    }
    return map;
  }
}
