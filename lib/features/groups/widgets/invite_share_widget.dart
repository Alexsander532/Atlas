library invite_share_widget;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget para exibir e compartilhar o código de convite.
class InviteShareWidget extends StatelessWidget {
  final String inviteCode;
  final String groupName;
  final bool isDetailed;

  const InviteShareWidget({
    super.key,
    required this.inviteCode,
    required this.groupName,
    this.isDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDetailed) {
      return _buildDetailedLayout(context);
    }
    return _buildCompactLayout(context);
  }

  Widget _buildCompactLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Código
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  inviteCode,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Botões
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _copyCode(context),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.share, color: Colors.black87),
            const SizedBox(width: 12),
            Text(
              inviteCode,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => _copyCode(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Convidar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado! 📋'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }
}
