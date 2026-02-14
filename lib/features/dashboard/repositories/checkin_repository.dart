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

  /// Realiza check-in para o usuário (em um grupo específico).
  Future<CheckinModel> createCheckin({
    required String userId,
    required String userName,
    required String title,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
    required String groupId,
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
      groupId: groupId,
    );
  }

  /// Verifica se o usuário já fez check-in hoje neste grupo.
  Future<bool> hasCheckinToday(String userId, {required String groupId}) async {
    if (userId.isEmpty) return false;

    return await _checkinService.hasCheckedInToday(userId, groupId: groupId);
  }

  /// Busca o ranking de membros do grupo por pontos.
  Future<List<RankingItem>> fetchRanking({
    int limit = 20,
    required String groupId,
  }) async {
    return await _rankingService.getRanking(groupId: groupId, limit: limit);
  }

  /// Busca o histórico de check-ins do usuário no grupo.
  Future<List<CheckinModel>> fetchHistory(
    String userId, {
    int limit = 50,
    required String groupId,
  }) async {
    if (userId.isEmpty) return [];

    return await _checkinService.getUserCheckins(
      userId,
      limit: limit,
      groupId: groupId,
    );
  }

  /// Retorna o total de pontos (check-ins) do usuário no grupo.
  Future<int> getUserScore(String userId, {required String groupId}) async {
    if (userId.isEmpty) return 0;

    return await _checkinService.getUserScore(userId, groupId: groupId);
  }

  /// Busca os check-ins recentes do grupo.
  Future<List<CheckinModel>> getRecentCheckins({
    int limit = 20,
    required String groupId,
  }) async {
    return await _checkinService.getRecentCheckins(
      limit: limit,
      groupId: groupId,
    );
  }
}
