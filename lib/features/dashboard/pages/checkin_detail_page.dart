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
    final backgroundColor = const Color(0xFFF7F9FA); // Light mode background

    // Formata a data incluindo a hora local original do check-in (createdAt)
    final dateFormatted = _formatDateTime(checkin.createdAt);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // AppBar com foto
                  SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.height * 0.45,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: backgroundColor,
                    iconTheme: const IconThemeData(color: Colors.black87),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildImageHeader(context, colorScheme),
                    ),
                  ),

                  // Conteúdo Principal
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            checkin.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Autor e data
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    colorScheme.primary, // App Blue Theme
                                child: Text(
                                  checkin.userName.isNotEmpty
                                      ? checkin.userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      checkin.userName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 16,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormatted,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.black87,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Descrição e Corpo
                          if (checkin.description != null &&
                              checkin.description!.isNotEmpty)
                            Text(
                              checkin.description!,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            Text(
                              'Nenhuma descrição adicionada.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.black45,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                          // Preenche espaço para manter scroll limpo
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Área de comentários fixada no fundo
            _buildCommentSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context, ColorScheme colorScheme) {
    if (checkin.imageUrl != null) {
      return GestureDetector(
        onTap: () => _openImageViewer(context),
        child: Hero(
          tag: 'checkin_${checkin.id}',
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(checkin.imageUrl!),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
      );
    }

    // Fallback vazio
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 80,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sem foto do check-in',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Ícone de emoji extra (placeholder)
            IconButton(
              icon: const Icon(
                Icons.add_reaction_outlined,
                color: Colors.black87,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            // Input de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Adicionar comentário...',
                    hintStyle: TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botão de Enviar (visual)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, size: 20, color: Colors.black45),
                onPressed:
                    () {}, // Funcionalidade de comentar pronta pro backend
              ),
            ),
          ],
        ),
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

  String _formatDateTime(DateTime date) {
    return DateFormat("d 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR').format(date);
  }
}
