/// ============================================================================
/// DASHBOARD CUBIT - Controlador de Estado do Dashboard
/// ============================================================================
///
/// Gerencia o estado do Dashboard incluindo:
/// - Check-in diário
/// - Ranking de usuários
/// - Histórico de atividades
///
/// ============================================================================
library dashboard_cubit;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/checkin_repository.dart';
import '../services/checkin_service.dart';
import '../services/ranking_service.dart';
import '../models/checkin_model.dart';
import 'dashboard_state.dart';

/// Cubit responsável pelo gerenciamento do Dashboard.
class DashboardCubit extends Cubit<DashboardState> {
  /// Repositório de check-in
  final CheckinRepository _checkinRepository;

  /// ID do usuário logado
  final String _userId;

  /// Nome do usuário logado
  final String _userName;

  /// Construtor do DashboardCubit.
  ///
  /// Recebe o repositório e dados do usuário logado.
  DashboardCubit({
    required CheckinRepository checkinRepository,
    required String userId,
    required String userName,
  }) : _checkinRepository = checkinRepository,
       _userId = userId,
       _userName = userName,
       super(const DashboardInitial());

  // ============================================================
  // MÉTODOS PÚBLICOS
  // ============================================================

  /// Carrega todos os dados do Dashboard.
  ///
  /// Chamado quando a tela é aberta.
  Future<void> loadDashboard() async {
    emit(const DashboardLoading());

    try {
      // Carrega dados em paralelo para performance
      final results = await Future.wait([
        _checkinRepository.hasCheckinToday(_userId),
        _checkinRepository.fetchRanking(limit: 10),
        _checkinRepository.fetchHistory(_userId, limit: 7),
        _checkinRepository.getStreakData(_userId),
      ]);

      final streakData = results[3] as Map<String, dynamic>;

      emit(
        DashboardLoaded(
          hasCheckedInToday: results[0] as bool,
          ranking: (results[1] as List).cast<RankingItem>(),
          recentActivity: (results[2] as List).cast<CheckinModel>(),
          totalCheckins: streakData['totalCheckins'] as int,
          userName: _userName,
        ),
      );
    } catch (e) {
      emit(DashboardError('Erro ao carregar dados: ${e.toString()}'));
    }
  }

  /// Realiza o check-in diário.
  ///
  /// Obs: O check-in agora é feito via formulário separado.
  /// Este método é mantido para compatibilidade.
  Future<void> performCheckin() async {
    // Obtém dados atuais se disponíveis
    final currentState = state;
    if (currentState is! DashboardLoaded) {
      emit(const DashboardError('Dashboard não carregado'));
      return;
    }

    // Verifica se já fez check-in
    if (currentState.hasCheckedInToday) {
      emit(const DashboardError('Você já fez check-in hoje!'));
      // Restaura estado anterior
      emit(currentState);
      return;
    }

    // Emite estado de loading mantendo dados visíveis
    emit(DashboardCheckinInProgress(currentState));

    try {
      // Nota: O check-in completo agora é feito via CheckinFormPage
      // Este método apenas recarrega os dados
      await loadDashboard();
    } on CheckinException catch (e) {
      emit(DashboardError(e.message));
      // Restaura estado anterior após mostrar erro
      emit(currentState);
    } catch (e) {
      emit(const DashboardError('Erro ao fazer check-in. Tente novamente.'));
      emit(currentState);
    }
  }

  /// Atualiza os dados do Dashboard.
  ///
  /// Chamado por pull-to-refresh ou após ações.
  Future<void> refresh() async {
    await loadDashboard();
  }
}
