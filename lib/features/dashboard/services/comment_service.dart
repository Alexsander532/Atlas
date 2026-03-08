import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adiciona um novo comentário na subcoleção 'comments' do check-in
  Future<void> addComment({
    required String checkinId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    final commentRef = _firestore
        .collection('checkins')
        .doc(checkinId)
        .collection('comments')
        .doc();

    final model = CommentModel(
      id: commentRef.id,
      checkinId: checkinId,
      userId: userId,
      userName: userName,
      text: text,
      createdAt: DateTime.now(), // Será reescrito pelo serverTimestamp
    );

    await commentRef.set(model.toMap());
  }

  /// Recupera os comentários de um check-in de forma reativa
  Stream<List<CommentModel>> getCommentsStream(String checkinId) {
    return _firestore
        .collection('checkins')
        .doc(checkinId)
        .collection('comments')
        .orderBy('createdAt', descending: false) // oldest first
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CommentModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Deleta um comentário (opcional, para futuras features)
  Future<void> deleteComment(String checkinId, String commentId) async {
    await _firestore
        .collection('checkins')
        .doc(checkinId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}
