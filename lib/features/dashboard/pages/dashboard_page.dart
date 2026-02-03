/// ============================================================================
/// DASHBOARD PAGE - Tela Principal do Aplicativo
/// ============================================================================
///
/// Tela principal após o login, contendo:
/// - Saudação ao usuário
/// - Card de check-in diário
/// - Ranking de constância
/// - Histórico de atividades
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/activity_card.dart';
import '../widgets/checkin_card.dart';
import '../widgets/ranking_card.dart';

/// Página principal do Dashboard.
///
/// Carrega dados automaticamente ao ser montada
/// e reage a mudanças de estado do [DashboardCubit].
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Carrega dados ao iniciar
    context.read<DashboardCubit>().loadDashboard();
  }

  /// Realiza o logout
  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().signOut();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Redireciona para login ao fazer logout
        if (state is AuthUnauthenticated || state is AuthInitial) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Atlas'),
          actions: [
            // Botão de refresh
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<DashboardCubit>().refresh(),
              tooltip: 'Atualizar',
            ),
            // Botão de logout
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _onLogout,
              tooltip: 'Sair',
            ),
          ],
        ),
        body: BlocConsumer<DashboardCubit, DashboardState>(
          listener: (context, state) {
            // Exibe erros como SnackBar
            if (state is DashboardError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            // Estado de loading inicial
            if (state is DashboardInitial || state is DashboardLoading) {
              return const LoadingIndicator(message: 'Carregando...');
            }

            // Obtém dados do estado
            DashboardLoaded data;
            bool isCheckinLoading = false;

            if (state is DashboardLoaded) {
              data = state;
            } else if (state is DashboardCheckinInProgress) {
              data = state.currentData;
              isCheckinLoading = true;
            } else if (state is DashboardError) {
              // Se erro, tenta usar dados anteriores ou mostra erro
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar dados',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<DashboardCubit>().loadDashboard(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            } else {
              // Estado desconhecido
              return const LoadingIndicator();
            }

            // Conteúdo do Dashboard
            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ====== SAUDAÇÃO ======
                    Text(
                      'Olá, ${data.userName}! 👋',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continue sua sequência de leitura!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ====== CARD DE CHECK-IN ======
                    CheckinCard(
                      hasCheckedInToday: data.hasCheckedInToday,
                      totalCheckins: data.totalCheckins,
                      isLoading: isCheckinLoading,
                      onCheckin: () =>
                          context.read<DashboardCubit>().performCheckin(),
                    ),
                    const SizedBox(height: 16),

                    // ====== RANKING ======
                    RankingCard(
                      ranking: data.ranking,
                      currentUserId:
                          context.read<AuthCubit>().state is AuthAuthenticated
                          ? (context.read<AuthCubit>().state
                                    as AuthAuthenticated)
                                .user
                                .id
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ====== ATIVIDADES RECENTES ======
                    ActivityCard(activities: data.recentActivity),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
