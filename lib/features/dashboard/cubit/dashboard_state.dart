/// ============================================================================
/// DASHBOARD STATE - Estados do Dashboard
/// ============================================================================
///
/// Define todos os estados possíveis do Dashboard.
///
/// ESTADOS:
/// - [DashboardInitial]: Estado inicial
/// - [DashboardLoading]: Carregando dados
/// - [DashboardLoaded]: Dados carregados com sucesso
/// - [DashboardError]: Erro ao carregar dados
///
/// ============================================================================
library dashboard_state;

import 'package:equatable/equatable.dart';
import '../models/checkin_model.dart';
import '../services/ranking_service.dart';

/// Classe base abstrata para todos os estados do Dashboard.
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial do Dashboard.
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Estado de carregamento.
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Estado com dados carregados.
///
/// Contém todas as informações necessárias para exibir o Dashboard:
/// - Status do check-in de hoje
/// - Ranking de usuários
/// - Histórico recente
class DashboardLoaded extends DashboardState {
  /// Se o usuário já fez check-in hoje
  final bool hasCheckedInToday;

  /// Ranking de usuários por constância
  final List<RankingItem> ranking;

  /// Histórico recente de check-ins do usuário
  final List<CheckinModel> recentActivity;

  /// Total de check-ins do usuário
  final int totalCheckins;

  /// Nome do usuário (para saudação)
  final String userName;

  const DashboardLoaded({
    required this.hasCheckedInToday,
    required this.ranking,
    required this.recentActivity,
    required this.totalCheckins,
    required this.userName,
  });

  /// Cria uma cópia com campos alterados.
  DashboardLoaded copyWith({
    bool? hasCheckedInToday,
    List<RankingItem>? ranking,
    List<CheckinModel>? recentActivity,
    int? totalCheckins,
    String? userName,
  }) {
    return DashboardLoaded(
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      ranking: ranking ?? this.ranking,
      recentActivity: recentActivity ?? this.recentActivity,
      totalCheckins: totalCheckins ?? this.totalCheckins,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [
    hasCheckedInToday,
    ranking,
    recentActivity,
    totalCheckins,
    userName,
  ];
}

/// Estado de erro.
class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado de loading durante check-in.
///
/// Diferente de DashboardLoading, este mantém os dados
/// atuais visíveis enquanto processa o check-in.
class DashboardCheckinInProgress extends DashboardState {
  /// Dados atuais enquanto processa
  final DashboardLoaded currentData;

  const DashboardCheckinInProgress(this.currentData);

  @override
  List<Object?> get props => [currentData];
}
