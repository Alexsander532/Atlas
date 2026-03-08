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
  final String? userPhotoUrl;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final String groupId;

  MessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.userPhotoUrl,
    this.editedAt,
    this.isDeleted = false,
    required this.groupId,
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
      userPhotoUrl: data['userPhotoUrl'],
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] ?? false,
      groupId: data['groupId'] ?? '',
    );
  }

  /// Converte para Map para salvar no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'userPhotoUrl': userPhotoUrl,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
      'groupId': groupId,
    };
  }

  /// Cria cópia com campos alterados.
  MessageModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? text,
    DateTime? createdAt,
    String? userPhotoUrl,
    DateTime? editedAt,
    bool? isDeleted,
    String? groupId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      groupId: groupId ?? this.groupId,
    );
  }
}
