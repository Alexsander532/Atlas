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

import '../models/checkin_model.dart';
import '../models/ranking_model.dart';
import '../services/checkin_service.dart';

/// Repositório de check-in.
///
/// Fornece uma interface limpa para operações de check-in,
/// abstraindo os detalhes do [CheckinService].
class CheckinRepository {
  /// Instância do serviço de check-in.
  final CheckinService _checkinService;

  /// Construtor que recebe o serviço de check-in.
  CheckinRepository(this._checkinService);

  // ============================================================
  // MÉTODOS PÚBLICOS
  // ============================================================

  /// Realiza check-in para o usuário.
  ///
  /// Regras:
  /// - Apenas 1 check-in por dia
  /// - Valida userId antes de criar
  ///
  /// Lança [CheckinException] se já existir check-in no dia.
  Future<CheckinModel> createCheckin(String userId) async {
    if (userId.isEmpty) {
      throw const CheckinException('Usuário inválido');
    }

    return await _checkinService.createCheckin(userId);
  }

  /// Verifica se o usuário já fez check-in hoje.
  Future<bool> hasCheckinToday(String userId) async {
    if (userId.isEmpty) return false;

    return await _checkinService.hasCheckinToday(userId);
  }

  /// Busca o ranking de usuários por total de check-ins.
  Future<List<RankingModel>> fetchRanking({int limit = 10}) async {
    return await _checkinService.fetchRanking(limit: limit);
  }

  /// Busca o histórico de check-ins do usuário.
  Future<List<CheckinModel>> fetchHistory(
    String userId, {
    int limit = 7,
  }) async {
    if (userId.isEmpty) return [];

    return await _checkinService.fetchHistory(userId, limit: limit);
  }

  /// Retorna o total de check-ins do usuário.
  Future<int> getTotalCheckins(String userId) async {
    if (userId.isEmpty) return 0;

    return await _checkinService.getTotalCheckins(userId);
  }
}
