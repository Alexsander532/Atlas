/// ============================================================================
/// CHECKIN REPOSITORY - Repositório de Check-in
/// ============================================================================
///
/// Camada de abstração entre o Cubit e o Service de check-in.
///
/// RESPONSABILIDADES:
/// - Abstrair detalhes de implementação do Service
/// - Aplicar regras de negócio
/// - Validar dados antes de enviar ao Service
/// - Facilitar testes com mocks
///
/// ============================================================================
library checkin_repository;

import 'dart:io';
import 'dart:typed_data';

import '../models/checkin_model.dart';
import '../services/checkin_service.dart';
import '../services/ranking_service.dart';

/// Repositório de check-in.
///
/// Fornece uma interface limpa para operações de check-in,
/// abstraindo os detalhes do [CheckinService].
class CheckinRepository {
  /// Instância do serviço de check-in.
  final CheckinService _checkinService;
  final RankingService _rankingService;

  /// Construtor que recebe os serviços.
  CheckinRepository({
    CheckinService? checkinService,
    RankingService? rankingService,
  }) : _checkinService = checkinService ?? CheckinService(),
       _rankingService = rankingService ?? RankingService();

  // ============================================================
  // MÉTODOS PÚBLICOS
  // ============================================================

  /// Realiza check-in para o usuário.
  ///
  /// Regras:
  /// - Apenas 1 check-in por dia
  /// - Requer título e foto
  ///
  /// Lança [CheckinException] se já existir check-in no dia.
  Future<CheckinModel> createCheckin({
    required String userId,
    required String userName,
    required String title,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    if (userId.isEmpty) {
      throw const CheckinException('Usuário inválido');
    }

    return await _checkinService.performCheckin(
      userId: userId,
      userName: userName,
      title: title,
      description: description,
      imageFile: imageFile,
      imageBytes: imageBytes,
    );
  }

  /// Verifica se o usuário já fez check-in hoje.
  Future<bool> hasCheckinToday(String userId) async {
    if (userId.isEmpty) return false;

    return await _checkinService.hasCheckedInToday(userId);
  }

  /// Busca o ranking de usuários por streak.
  Future<List<RankingItem>> fetchRanking({int limit = 20}) async {
    return await _rankingService.getRanking(limit: limit);
  }

  /// Busca o histórico de check-ins do usuário.
  Future<List<CheckinModel>> fetchHistory(
    String userId, {
    int limit = 50,
  }) async {
    if (userId.isEmpty) return [];

    return await _checkinService.getUserCheckins(userId, limit: limit);
  }

  /// Retorna os dados de streak do usuário.
  Future<Map<String, dynamic>> getStreakData(String userId) async {
    if (userId.isEmpty) {
      return {'currentStreak': 0, 'maxStreak': 0, 'totalCheckins': 0};
    }

    return await _checkinService.getUserStreakData(userId);
  }

  /// Busca os check-ins recentes de todos os usuários.
  Future<List<CheckinModel>> getRecentCheckins({int limit = 20}) async {
    return await _checkinService.getRecentCheckins(limit: limit);
  }
}
