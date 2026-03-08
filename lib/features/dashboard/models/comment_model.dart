import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final String id;
  final String checkinId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.checkinId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime createdAt = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        createdAt = DateTime.parse(map['createdAt']);
      }
    }

    return CommentModel(
      id: id,
      checkinId: map['checkinId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      text: map['text'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'checkinId': checkinId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, checkinId, userId, userName, text, createdAt];
}
