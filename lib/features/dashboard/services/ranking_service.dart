/// ============================================================================
/// RANKING SERVICE - Serviço de Ranking
/// ============================================================================
///
/// Busca e ordena os usuários por streak para o ranking.
///
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de item do ranking.
class RankingItem {
  final String id;
  final String name;
  final int currentStreak;
  final int maxStreak;
  final int totalCheckins;
  final int position;

  const RankingItem({
    required this.id,
    required this.name,
    required this.currentStreak,
    required this.maxStreak,
    required this.totalCheckins,
    required this.position,
  });
}

/// Serviço de ranking.
class RankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca o ranking ordenado por currentStreak (decrescente).
  ///
  /// [limit] - Número máximo de usuários a retornar
  Future<List<RankingItem>> getRanking({int limit = 50}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('currentStreak', descending: true)
        .orderBy('totalCheckins', descending: true)
        .limit(limit)
        .get();

    final ranking = <RankingItem>[];
    int position = 1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      ranking.add(
        RankingItem(
          id: doc.id,
          name: data['name'] ?? 'Usuário',
          currentStreak: data['currentStreak'] ?? 0,
          maxStreak: data['maxStreak'] ?? 0,
          totalCheckins: data['totalCheckins'] ?? 0,
          position: position,
        ),
      );
      position++;
    }

    return ranking;
  }

  /// Busca a posição do usuário no ranking.
  Future<int> getUserPosition(String userId) async {
    final ranking = await getRanking(limit: 100);

    for (int i = 0; i < ranking.length; i++) {
      if (ranking[i].id == userId) {
        return i + 1;
      }
    }

    return ranking.length + 1; // Se não encontrado, está no final
  }

  /// Stream do ranking em tempo real.
  Stream<List<RankingItem>> watchRanking({int limit = 50}) {
    return _firestore
        .collection('users')
        .orderBy('currentStreak', descending: true)
        .orderBy('totalCheckins', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final ranking = <RankingItem>[];
          int position = 1;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            ranking.add(
              RankingItem(
                id: doc.id,
                name: data['name'] ?? 'Usuário',
                currentStreak: data['currentStreak'] ?? 0,
                maxStreak: data['maxStreak'] ?? 0,
                totalCheckins: data['totalCheckins'] ?? 0,
                position: position,
              ),
            );
            position++;
          }

          return ranking;
        });
  }
}
