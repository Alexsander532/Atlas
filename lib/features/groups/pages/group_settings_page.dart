/// ============================================================================
/// GROUP SETTINGS PAGE - Configurações do Desafio
/// ============================================================================
///
/// Exibe configurações do desafio/grupo:
/// - Informações do desafio (nome, duração, datas)
/// - Código de convite (copiar/compartilhar)
/// - Lista de membros com pontuação
/// - Opção de sair do grupo
/// - Admin: remover membros
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
import '../widgets/invite_share_widget.dart';

/// Página de configurações do grupo/desafio.
class GroupSettingsPage extends StatelessWidget {
  final String groupId;

  const GroupSettingsPage({super.key, required this.groupId});

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
      )..loadGroups(activeGroupId: groupId),
      child: _GroupSettingsContent(
        groupId: groupId,
        currentUserId: authState.user.id,
      ),
    );
  }
}

class _GroupSettingsContent extends StatelessWidget {
  final String groupId;
  final String currentUserId;

  const _GroupSettingsContent({
    required this.groupId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações do Desafio')),
      body: BlocBuilder<GroupCubit, GroupState>(
        builder: (context, state) {
          if (state is GroupLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GroupsLoaded && state.activeGroup != null) {
            final group = state.activeGroup!;
            return _buildContent(context, group, theme, colorScheme);
          }

          return const Center(child: Text('Grupo não encontrado'));
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    GroupModel group,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isAdmin = group.createdBy == currentUserId;
    final progress = group.durationDays > 0
        ? (group.daysElapsed / group.durationDays).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ====== INFORMAÇÕES DO DESAFIO ======
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: group.isActive
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          group.isActive
                              ? Icons.emoji_events
                              : Icons.lock_clock,
                          color: group.isActive
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (group.description != null &&
                                group.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  group.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progresso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: group.isActive
                          ? colorScheme.primary
                          : colorScheme.outline,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dia ${group.daysElapsed} de ${group.durationDays}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        group.isActive
                            ? '${group.daysRemaining} dias restantes'
                            : 'Finalizado',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: group.isActive
                              ? colorScheme.primary
                              : colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberCount} membros',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Admin',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ====== CÓDIGO DE CONVITE ======
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código de Convite',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compartilhe para convidar novos participantes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: InviteShareWidget(
                      inviteCode: group.inviteCode,
                      groupName: group.name,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ====== AÇÕES ======
          OutlinedButton.icon(
            onPressed: () => _confirmLeaveGroup(context, group),
            icon: Icon(Icons.exit_to_app, color: colorScheme.error),
            label: Text(
              'Sair do Desafio',
              style: TextStyle(color: colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmLeaveGroup(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do Desafio?'),
        content: Text(
          'Tem certeza que deseja sair do desafio "${group.name}"? Seus dados de check-in serão mantidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<GroupCubit>().leaveGroup(group.id);
              Navigator.pop(context); // Volta para a lista
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
