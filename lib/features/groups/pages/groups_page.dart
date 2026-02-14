/// ============================================================================
/// GROUPS PAGE - Listagem de Desafios/Grupos
/// ============================================================================
///
/// Exibe os desafios do usuário com cards visuais.
/// Permite criar novos desafios ou entrar com código.
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../cubit/group_cubit.dart';
import '../cubit/group_state.dart';
import '../models/group_model.dart';
import '../repositories/group_repository.dart';
import 'create_group_page.dart';
import 'join_group_page.dart';

/// Página de listagem de grupos/desafios.
class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (_) => GroupCubit(
        groupRepository: GroupRepository(),
        userId: authState.user.id,
      )..loadGroups(activeGroupId: authState.user.activeGroupId),
      child: const _GroupsPageContent(),
    );
  }
}

class _GroupsPageContent extends StatelessWidget {
  const _GroupsPageContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Desafios'), centerTitle: true),
      body: BlocConsumer<GroupCubit, GroupState>(
        listener: (context, state) {
          if (state is GroupJoined) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Entrou no desafio "${state.group.name}"! 🎉'),
                backgroundColor: Colors.green,
              ),
            );
            // Navega para dashboard com o grupo ativo
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
          if (state is GroupCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Desafio "${state.group.name}" criado! 🎉'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
          if (state is GroupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GroupLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GroupsLoaded) {
            if (state.groups.isEmpty) {
              return _buildEmptyState(context, theme, colorScheme);
            }
            return _buildGroupsList(context, state.groups, theme, colorScheme);
          }

          return _buildEmptyState(context, theme, colorScheme);
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            onPressed: () => _openJoinPage(context),
            backgroundColor: colorScheme.secondaryContainer,
            child: Icon(Icons.link, color: colorScheme.onSecondaryContainer),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => _openCreatePage(context),
            icon: const Icon(Icons.add),
            label: const Text('Criar Desafio'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum desafio ainda',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um novo desafio de leitura ou entre em um existente com um código de convite.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _openCreatePage(context),
              icon: const Icon(Icons.add),
              label: const Text('Criar Desafio'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openJoinPage(context),
              icon: const Icon(Icons.link),
              label: const Text('Entrar com Código'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList(
    BuildContext context,
    List<GroupModel> groups,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Separar ativos e finalizados
    final active = groups.where((g) => g.isActive).toList();
    final ended = groups.where((g) => !g.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          Text(
            '🟢 Desafios Ativos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...active.map((g) => _buildGroupCard(context, g, theme, colorScheme)),
          const SizedBox(height: 24),
        ],
        if (ended.isNotEmpty) ...[
          Text(
            '🔴 Finalizados',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...ended.map((g) => _buildGroupCard(context, g, theme, colorScheme)),
        ],
        const SizedBox(height: 80), // Espaço para FAB
      ],
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    GroupModel group,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isActive = group.isActive;
    final progress = group.durationDays > 0
        ? (group.daysElapsed / group.durationDays).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 0,
      color: isActive
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Seleciona o grupo e vai para o dashboard
          context.read<GroupCubit>().selectGroup(group);
          Navigator.pushReplacementNamed(context, '/dashboard');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Ícone
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isActive ? Icons.emoji_events : Icons.lock_clock,
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nome e info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isActive
                              ? '${group.daysRemaining} dias restantes'
                              : 'Finalizado',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isActive
                                ? colorScheme.primary
                                : colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Membros
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberCount}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Barra de progresso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: isActive ? colorScheme.primary : colorScheme.outline,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dia ${group.daysElapsed} de ${group.durationDays}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreatePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupPage()),
    );
  }

  void _openJoinPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinGroupPage()),
    );
  }
}
