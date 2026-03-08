/// ============================================================================
/// CHECKIN CARD - Card de Check-in Diário
/// ============================================================================
///
/// Widget principal do Dashboard que permite ao usuário
/// fazer seu check-in diário de leitura.
///
/// ESTADOS:
/// - Disponível: Botão azul para fazer check-in
/// - Já feito: Botão verde indicando sucesso
/// - Loading: Indicador de carregamento
///
/// ============================================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Card de check-in diário.
///
/// Exibe um botão grande para o usuário registrar
/// que leu hoje.
class CheckinCard extends StatelessWidget {
  /// Se o usuário já fez check-in hoje
  final bool hasCheckedInToday;

  /// Callback executado ao fazer check-in
  final VoidCallback? onCheckin;

  /// Se está processando o check-in
  final bool isLoading;

  /// Total de check-ins do usuário
  final int totalCheckins;

  const CheckinCard({
    super.key,
    required this.hasCheckedInToday,
    this.onCheckin,
    this.isLoading = false,
    this.totalCheckins = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define cores baseadas no estado
    final backgroundColor = hasCheckedInToday
        ? AppTheme.successColor.withValues(alpha: 0.1)
        : colorScheme.primaryContainer;

    final buttonColor = hasCheckedInToday
        ? AppTheme.successColor
        : colorScheme.primary;

    final buttonTextColor = hasCheckedInToday
        ? Colors.white
        : colorScheme.onPrimary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ====== ÍCONE ANIMADO ======
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasCheckedInToday
                    ? Icons.check_circle_rounded
                    : Icons.menu_book_rounded,
                size: 48,
                color: buttonColor,
              ),
            ),
            const SizedBox(height: 16),

            // ====== TÍTULO ======
            Text(
              hasCheckedInToday ? 'Check-in Feito!' : 'Leu hoje?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // ====== SUBTÍTULO ======
            Text(
              hasCheckedInToday
                  ? 'Parabéns! Você registrou sua leitura hoje.'
                  : 'Registre sua leitura diária e suba no ranking!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ====== BOTÃO DE CHECK-IN ======
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: hasCheckedInToday || isLoading ? null : onCheckin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  disabledBackgroundColor: hasCheckedInToday
                      ? AppTheme.successColor.withValues(alpha: 0.5)
                      : null,
                  disabledForegroundColor: hasCheckedInToday
                      ? Colors.white.withValues(alpha: 0.8)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasCheckedInToday
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasCheckedInToday ? 'Concluído' : 'Fazer Check-in',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ====== CONTADOR DE TOTAL ======
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 20,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$totalCheckins dias de leitura',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
