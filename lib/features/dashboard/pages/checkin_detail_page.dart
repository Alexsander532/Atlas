/// ============================================================================
/// CHECKIN DETAIL PAGE - Detalhes do Check-in
/// ============================================================================
///
/// Exibe os detalhes de um check-in específico: foto, título, descrição, etc.
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/checkin_model.dart';
import '../../../core/widgets/image_viewer_page.dart';

/// Página de detalhes do check-in.
class CheckinDetailPage extends StatelessWidget {
  final CheckinModel checkin;

  const CheckinDetailPage({super.key, required this.checkin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Formata a data
    final dateFormatted = _formatDate(checkin.date);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // AppBar com foto
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: checkin.imageUrl != null
                  ? GestureDetector(
                      onTap: () => _openImageViewer(context),
                      child: Hero(
                        tag: 'checkin_${checkin.id}',
                        child: Image.network(
                          checkin.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book,
                              size: 64,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sem foto',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    checkin.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Autor e data
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          checkin.userName.isNotEmpty
                              ? checkin.userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checkin.userName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            dateFormatted,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Descrição
                  if (checkin.description != null &&
                      checkin.description!.isNotEmpty) ...[
                    Text(
                      'Sobre a leitura',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      checkin.description!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ] else
                    Text(
                      'Nenhuma descrição adicionada.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(BuildContext context) {
    if (checkin.imageUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerPage(
          imageUrl: checkin.imageUrl,
          tag: 'checkin_${checkin.id}',
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
