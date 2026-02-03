/// ============================================================================
/// RANKING CARD - Card de Ranking de Usuários
/// ============================================================================
///
/// Exibe o ranking dos usuários por total de check-ins.
///
/// Os primeiros 3 lugares recebem destaque visual especial.
///
/// ============================================================================

import 'package:flutter/material.dart';

import '../models/ranking_model.dart';

/// Card que exibe o ranking de usuários por constância.
class RankingCard extends StatelessWidget {
  /// Lista de usuários no ranking
  final List<RankingModel> ranking;

  /// ID do usuário logado (para destacar)
  final String? currentUserId;

  const RankingCard({super.key, required this.ranking, this.currentUserId});

  /// Retorna o ícone/cor para a posição no ranking
  Widget _buildPositionBadge(int position, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Cores especiais para top 3
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (position) {
      case 1:
        backgroundColor = const Color(0xFFFFD700); // Ouro
        textColor = Colors.black87;
        icon = Icons.emoji_events_rounded;
        break;
      case 2:
        backgroundColor = const Color(0xFFC0C0C0); // Prata
        textColor = Colors.black87;
        icon = Icons.emoji_events_rounded;
        break;
      case 3:
        backgroundColor = const Color(0xFFCD7F32); // Bronze
        textColor = Colors.white;
        icon = Icons.emoji_events_rounded;
        break;
      default:
        backgroundColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        icon = null;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 18, color: textColor)
            : Text(
                position.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== CABEÇALHO ======
            Row(
              children: [
                Icon(Icons.leaderboard_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ranking de Constância',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ====== LISTA DE RANKING ======
            if (ranking.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Nenhum usuário no ranking ainda',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ranking.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = ranking[index];
                  final position = user.position ?? (index + 1);
                  final isCurrentUser = user.id == currentUserId;

                  return Container(
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: _buildPositionBadge(position, context),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.userName,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Você',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user.totalCheckins}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
