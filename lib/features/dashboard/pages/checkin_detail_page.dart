import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../models/checkin_model.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';
import '../../../core/widgets/image_viewer_page.dart';

/// Página de detalhes do check-in.
class CheckinDetailPage extends StatefulWidget {
  final CheckinModel checkin;
  final bool autoFocusComment;

  const CheckinDetailPage({
    super.key,
    required this.checkin,
    this.autoFocusComment = false,
  });

  @override
  State<CheckinDetailPage> createState() => _CheckinDetailPageState();
}

class _CheckinDetailPageState extends State<CheckinDetailPage> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoFocusComment) {
      // Delay to ensure the widget is fully built before requesting focus
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _commentFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSubmitting = true);

    try {
      await _commentService.addComment(
        checkinId: widget.checkin.id,
        userId: authState.user.id,
        userName: authState.user.name,
        text: text,
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar comentário')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = const Color(0xFFF7F9FA); // Light mode background

    // Formata a data incluindo a hora local original do check-in (createdAt)
    final dateFormatted = _formatDateTime(widget.checkin.createdAt);

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
                            widget.checkin.title,
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
                                  widget.checkin.userName.isNotEmpty
                                      ? widget.checkin.userName[0].toUpperCase()
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
                                      widget.checkin.userName,
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
                          if (widget.checkin.description != null &&
                              widget.checkin.description!.isNotEmpty)
                            Text(
                              widget.checkin.description!,
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

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Comentários
                          Text(
                            'Comentários',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          StreamBuilder<List<CommentModel>>(
                            stream: _commentService.getCommentsStream(
                              widget.checkin.id,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return const Text(
                                  'Erro ao carregar comentários.',
                                );
                              }

                              final comments = snapshot.data ?? [];

                              if (comments.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: Text(
                                      'Seja o primeiro a comentar!',
                                      style: TextStyle(color: Colors.black45),
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: comments.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.grey[300],
                                        child: Text(
                                          comment.userName.isNotEmpty
                                              ? comment.userName[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topRight: Radius.circular(16),
                                                  bottomLeft: Radius.circular(
                                                    16,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    16,
                                                  ),
                                                ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    comment.userName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat(
                                                      'dd/MM HH:mm',
                                                    ).format(comment.createdAt),
                                                    style: const TextStyle(
                                                      color: Colors.black45,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment.text,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),

                          // Preenche espaço para manter scroll limpo
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1,
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
    if (widget.checkin.imageUrl != null) {
      return GestureDetector(
        onTap: () => _openImageViewer(context),
        child: Hero(
          tag: 'checkin_${widget.checkin.id}',
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.checkin.imageUrl!),
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
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                  decoration: const InputDecoration(
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
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 20, color: Colors.black45),
                onPressed: _isSubmitting ? null : _submitComment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context) {
    if (widget.checkin.imageUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerPage(
          imageUrl: widget.checkin.imageUrl,
          tag: 'checkin_${widget.checkin.id}',
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat("d 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR').format(date);
  }
}
