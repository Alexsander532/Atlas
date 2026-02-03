/// ============================================================================
/// ACTIVITY CARD - Card de Histórico de Atividades
/// ============================================================================
///
/// Exibe o histórico recente de check-ins do usuário.
///
/// Mostra as últimas atividades com datas relativas
/// (hoje, ontem, há X dias).
///
/// ============================================================================

import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../models/checkin_model.dart';

/// Card que exibe o histórico recente de check-ins.
class ActivityCard extends StatelessWidget {
  /// Lista de check-ins recentes
  final List<CheckinModel> activities;

  const ActivityCard({super.key, required this.activities});

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
                Icon(Icons.history_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Atividades Recentes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ====== LISTA DE ATIVIDADES ======
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhuma atividade recente',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Faça seu primeiro check-in!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  final date =
                      AppDateUtils.parseCheckinKey(activity.date) ??
                      DateTime.now();
                  final relativeDate = AppDateUtils.formatRelative(date);
                  final fullDate = AppDateUtils.formatToDisplay(date);
                  final isToday = AppDateUtils.isToday(date);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isToday
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: isToday
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      'Check-in realizado',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      fullDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isToday
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        relativeDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isToday
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
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
