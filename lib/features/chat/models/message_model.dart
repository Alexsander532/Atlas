/// ============================================================================
/// MESSAGE MODEL - Modelo de Dados de Mensagem do Chat
/// ============================================================================
///
/// Representa uma mensagem enviada no chat em grupo.
///
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de mensagem do chat.
class MessageModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final DateTime? editedAt;

  MessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.editedAt,
  });

  /// Cria a partir de um documento Firestore.
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anônimo',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converte para Map para salvar no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  /// Cria cópia com campos alterados.
  MessageModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? text,
    DateTime? createdAt,
    DateTime? editedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}
