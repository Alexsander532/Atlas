/// ============================================================================
/// CHAT PLACEHOLDER PAGE - Página de Chat (Em breve)
/// ============================================================================

import 'package:flutter/material.dart';

/// Placeholder para a página de chat.
class ChatPlaceholderPage extends StatelessWidget {
  const ChatPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone animado
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            Text(
              'Chat do Grupo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Subtítulo
            Text(
              'Em breve...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Descrição
            Text(
              'Aqui você poderá conversar com os outros membros do grupo Restauração, compartilhar insights e motivar uns aos outros!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Badge "Em desenvolvimento"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction,
                    size: 18,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Em desenvolvimento',
                    style: TextStyle(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w500,
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
