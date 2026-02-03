/// ============================================================================
/// CHAT SERVICE - Serviço de Chat com Firestore
/// ============================================================================
///
/// Gerencia operações CRUD de mensagens no Firestore.
///
/// Funcionalidades:
/// - Stream de mensagens em tempo real
/// - Enviar mensagem
/// - Editar mensagem (apenas autor)
/// - Excluir mensagem (apenas autor)
///
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

/// Serviço para gerenciar mensagens do chat.
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Coleção de mensagens.
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');

  /// Stream de mensagens ordenadas por data (mais recentes por último).
  Stream<List<MessageModel>> getMessagesStream() {
    return _messagesCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Envia uma nova mensagem.
  Future<void> sendMessage({
    required String userId,
    required String userName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    await _messagesCollection.add({
      'userId': userId,
      'userName': userName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
    });
  }

  /// Edita uma mensagem existente.
  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    if (newText.trim().isEmpty) return;

    await _messagesCollection.doc(messageId).update({
      'text': newText.trim(),
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Exclui uma mensagem.
  Future<void> deleteMessage(String messageId) async {
    await _messagesCollection.doc(messageId).delete();
  }
}
