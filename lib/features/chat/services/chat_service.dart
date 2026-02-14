/// ============================================================================
/// CHAT SERVICE - Serviço de Chat com Firestore (por Grupo)
/// ============================================================================
///
/// Gerencia operações CRUD de mensagens no Firestore,
/// filtradas por grupo.
///
/// Funcionalidades:
/// - Stream de mensagens em tempo real (por grupo)
/// - Enviar mensagem (com groupId)
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

  /// Stream de mensagens ordenadas por data (por grupo).
  Stream<List<MessageModel>> getMessagesStream({required String groupId}) {
    return _messagesCollection
        .where('groupId', isEqualTo: groupId)
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
    String? userPhotoUrl,
    required String groupId,
  }) async {
    if (text.trim().isEmpty) return;

    await _messagesCollection.add({
      'userId': userId,
      'userName': userName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'userPhotoUrl': userPhotoUrl,
      'editedAt': null,
      'isDeleted': false,
      'groupId': groupId,
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

  /// Exclui uma mensagem (soft delete).
  Future<void> deleteMessage(String messageId) async {
    await _messagesCollection.doc(messageId).update({
      'isDeleted': true,
      'text': '', // Limpa o texto para privacidade/segurança
    });
  }

  /// Define o status de "digitando" do usuário.
  Future<void> setTypingStatus({
    required String userId,
    required String userName,
    required bool isTyping,
    required String groupId,
  }) async {
    final docRef = _firestore
        .collection('typing_status')
        .doc('${groupId}_$userId');

    if (isTyping) {
      await docRef.set({
        'userName': userName,
        'groupId': groupId,
        'lastTypedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.delete();
    }
  }

  /// Stream de usuários que estão digitando (no grupo).
  Stream<List<String>> getTypingUsersStream(
    String currentUserId, {
    required String groupId,
  }) {
    return _firestore
        .collection('typing_status')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) => !doc.id.endsWith('_$currentUserId'))
              .map((doc) => doc['userName'] as String)
              .toList();
        });
  }
}
