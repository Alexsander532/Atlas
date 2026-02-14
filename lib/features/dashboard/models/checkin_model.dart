/// ============================================================================
/// CHECKIN MODEL - Modelo de Check-in
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Representa um check-in de leitura.
class CheckinModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String? description;
  final String? imageUrl;
  final String date; // Formato: YYYY-MM-DD
  final DateTime createdAt;
  final String groupId;

  const CheckinModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    this.description,
    this.imageUrl,
    required this.date,
    required this.createdAt,
    required this.groupId,
  });

  /// Cria a partir de um documento do Firestore.
  factory CheckinModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckinModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      date: data['date'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      groupId: data['groupId'] ?? '',
    );
  }

  /// Converte para Map para salvar no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'date': date,
      'createdAt': Timestamp.fromDate(createdAt),
      'groupId': groupId,
    };
  }

  @override
  List<Object?> get props => [id, userId, date, groupId];
}
