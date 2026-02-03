/// ============================================================================
/// CHAT PAGE - Página de Chat em Grupo
/// ============================================================================
///
/// Interface do chat com:
/// - Lista de mensagens em tempo real
/// - Campo de texto para enviar mensagens
/// - Opções de editar/excluir ao segurar a própria mensagem
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

/// Página principal do chat em grupo.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Envia uma mensagem.
  void _sendMessage() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      userId: authState.user.id,
      userName: authState.user.name,
      text: text,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  /// Rola para o final da lista.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Mostra opções para a mensagem (editar/excluir).
  void _showMessageOptions(MessageModel message) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    if (message.userId != authState.user.id) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Diálogo para editar mensagem.
  void _showEditDialog(MessageModel message) {
    final editController = TextEditingController(text: message.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Mensagem'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Digite sua mensagem...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                _chatService.editMessage(
                  messageId: message.id,
                  newText: newText,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  /// Confirmação para excluir mensagem.
  void _showDeleteConfirmation(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Mensagem'),
        content: const Text('Tem certeza que deseja excluir esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _chatService.deleteMessage(message.id);
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // ====== CABEÇALHO ======
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Chat do Clube',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ====== LISTA DE MENSAGENS ======
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _chatService.getMessagesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar mensagens: ${snapshot.error}'),
                );
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma mensagem ainda',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seja o primeiro a enviar! 💬',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              // Rola para baixo quando há novas mensagens
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(messages[index]);
                },
              );
            },
          ),
        ),

        // ====== CAMPO DE ENVIO ======
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHigh,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói o balão de mensagem.
  Widget _buildMessageBubble(MessageModel message) {
    final authState = context.read<AuthCubit>().state;
    final isMyMessage =
        authState is AuthAuthenticated && authState.user.id == message.userId;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Align(
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMyMessage
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
              bottomRight: Radius.circular(isMyMessage ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome do autor (só para mensagens dos outros)
              if (!isMyMessage)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.userName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

              // Texto da mensagem
              Text(
                message.text,
                style: TextStyle(
                  color: isMyMessage
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),

              // Horário e indicador de editado
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMyMessage
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (message.editedAt != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(editado)',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: isMyMessage
                            ? colorScheme.onPrimary.withOpacity(0.7)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
