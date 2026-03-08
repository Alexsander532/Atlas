/// ============================================================================
/// RANKING SERVICE - Serviço de Ranking por Grupo
/// ============================================================================
///
/// Busca e ordena os membros por total de check-ins no desafio.
///
/// Pontuação: 1 check-in/dia = 1 ponto (máx 1 por dia).
/// Ranking = total de pontos no período do desafio.
///
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de item do ranking.
class RankingItem {
  final String id;
  final String name;
  final int totalCheckins;
  final int position;
  final String? photoUrl;

  const RankingItem({
    required this.id,
    required this.name,
    required this.totalCheckins,
    required this.position,
    this.photoUrl,
  });
}

/// Serviço de ranking por grupo.
class RankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca o ranking de um grupo ordenado por total de check-ins.
  ///
  /// [groupId] - ID do grupo/desafio
  /// [limit] - Número máximo de membros a retornar
  Future<List<RankingItem>> getRanking({
    required String groupId,
    int limit = 50,
  }) async {
    // 1. Busca o grupo para pegar os memberIds
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) return [];

    final memberIds = List<String>.from(groupDoc.data()?['memberIds'] ?? []);
    if (memberIds.isEmpty) return [];

    // 2. Busca todos os check-ins do grupo
    final checkinsSnapshot = await _firestore
        .collection('checkins')
        .where('groupId', isEqualTo: groupId)
        .get();

    // 3. Conta check-ins por usuário
    final Map<String, int> scoreCounts = {};
    final Map<String, String> userNames = {};

    for (final doc in checkinsSnapshot.docs) {
      final data = doc.data();
      final uId = data['userId'] as String? ?? '';
      final uName = data['userName'] as String? ?? 'Usuário';

      scoreCounts[uId] = (scoreCounts[uId] ?? 0) + 1;
      userNames[uId] = uName;
    }

    // 4. Busca dados dos usuários (para n omes e fotos de quem não tem check-in)
    final usersSnapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds.take(10).toList())
        .get();

    final Map<String, Map<String, dynamic>> usersData = {};
    for (final doc in usersSnapshot.docs) {
      usersData[doc.id] = doc.data();
    }

    // Se tiver mais de 10 membros, busca em batches
    if (memberIds.length > 10) {
      for (var i = 10; i < memberIds.length; i += 10) {
        final batch = memberIds.skip(i).take(10).toList();
        final batchSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in batchSnapshot.docs) {
          usersData[doc.id] = doc.data();
        }
      }
    }

    // 5. Constroi lista de ranking
    final ranking = memberIds.map((memberId) {
      final userData = usersData[memberId];
      return RankingItem(
        id: memberId,
        name: userNames[memberId] ?? userData?['name'] ?? 'Usuário',
        totalCheckins: scoreCounts[memberId] ?? 0,
        position: 0, // Será definido após ordenação
        photoUrl: userData?['photoUrl'],
      );
    }).toList();

    // 6. Ordena por total de check-ins (descrescente)
    ranking.sort((a, b) => b.totalCheckins.compareTo(a.totalCheckins));

    // 7. Aplica posições e limite
    final positioned = <RankingItem>[];
    for (int i = 0; i < ranking.length && i < limit; i++) {
      positioned.add(
        RankingItem(
          id: ranking[i].id,
          name: ranking[i].name,
          totalCheckins: ranking[i].totalCheckins,
          position: i + 1,
          photoUrl: ranking[i].photoUrl,
        ),
      );
    }

    return positioned;
  }

  /// Busca a posição do usuário no ranking do grupo.
  Future<int> getUserPosition(String userId, {required String groupId}) async {
    final ranking = await getRanking(groupId: groupId, limit: 100);

    for (int i = 0; i < ranking.length; i++) {
      if (ranking[i].id == userId) {
        return i + 1;
      }
    }

    return ranking.length + 1;
  }
}
