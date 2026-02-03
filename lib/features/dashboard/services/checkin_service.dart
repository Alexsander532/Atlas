/// ============================================================================
/// CHECKIN SERVICE - Serviço de Check-in
/// ============================================================================
///
/// Camada de integração com o provedor de dados de check-ins.
/// Atualmente implementado com MOCK para desenvolvimento.
///
/// PREPARAÇÃO PARA FIRESTORE:
///
/// Coleção: checkins
/// Documento: {userId}_{date}
/// Campos:
///   - userId: String
///   - date: String (yyyy-MM-dd)
///   - createdAt: Timestamp
///
/// Coleção: users (para ranking)
/// Documento: {userId}
/// Campos:
///   - name: String
///   - totalCheckins: Number (atualizado a cada check-in)
///
/// ============================================================================

import '../../../core/utils/date_utils.dart';
import '../models/checkin_model.dart';
import '../models/ranking_model.dart';

// TODO: [FIREBASE_REAL] Descomente quando integrar Firebase real
// import 'package:cloud_firestore/cloud_firestore.dart';

/// Exceção customizada para erros de check-in.
class CheckinException implements Exception {
  final String message;
  final String? code;

  const CheckinException(this.message, {this.code});

  @override
  String toString() => 'CheckinException: $message';
}

/// Serviço de check-in do aplicativo.
///
/// Responsável pela comunicação direta com Firestore (ou mock).
class CheckinService {
  // TODO: [FIREBASE_REAL] Descomente quando integrar Firebase real
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // DADOS MOCK - Remover quando integrar Firebase
  // ============================================================

  /// Check-ins mock (usuário já fez check-in em alguns dias)
  final Map<String, CheckinModel> _mockCheckins = {};

  /// Ranking mock com usuários fictícios
  final List<RankingModel> _mockRanking = [
    const RankingModel(
      id: 'user_003',
      userName: 'Maria Silva',
      totalCheckins: 45,
      position: 1,
    ),
    const RankingModel(
      id: 'user_004',
      userName: 'João Santos',
      totalCheckins: 38,
      position: 2,
    ),
    const RankingModel(
      id: 'user_001',
      userName: 'Usuário Teste',
      totalCheckins: 12,
      position: 3,
    ),
    const RankingModel(
      id: 'user_005',
      userName: 'Ana Costa',
      totalCheckins: 10,
      position: 4,
    ),
    const RankingModel(
      id: 'user_006',
      userName: 'Pedro Lima',
      totalCheckins: 7,
      position: 5,
    ),
  ];

  // ============================================================
  // MÉTODOS DE CHECK-IN
  // ============================================================

  /// Cria um novo check-in para o usuário.
  ///
  /// Lança [CheckinException] se já existir check-in no dia.
  ///
  /// Exemplo:
  /// ```dart
  /// await checkinService.createCheckin('user_001');
  /// ```
  Future<CheckinModel> createCheckin(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final today = AppDateUtils.todayKey;
    final docId = '${userId}_$today';

    // Verifica se já existe check-in hoje
    if (_mockCheckins.containsKey(docId)) {
      throw const CheckinException(
        'Você já fez check-in hoje!',
        code: 'already-checked-in',
      );
    }

    // TODO: [FIREBASE_REAL] Substitua pelo código abaixo:
    // final docRef = _firestore.collection('checkins').doc(docId);
    //
    // // Transação para garantir atomicidade
    // await _firestore.runTransaction((transaction) async {
    //   final doc = await transaction.get(docRef);
    //
    //   if (doc.exists) {
    //     throw const CheckinException('Você já fez check-in hoje!');
    //   }
    //
    //   final checkin = CheckinModel(
    //     userId: userId,
    //     date: today,
    //     createdAt: DateTime.now(),
    //   );
    //
    //   transaction.set(docRef, checkin.toMap());
    //
    //   // Incrementa contador no perfil do usuário
    //   final userRef = _firestore.collection('users').doc(userId);
    //   transaction.update(userRef, {
    //     'totalCheckins': FieldValue.increment(1),
    //   });
    // });

    // Implementação MOCK
    final checkin = CheckinModel(
      userId: userId,
      date: today,
      createdAt: DateTime.now(),
    );

    _mockCheckins[docId] = checkin;

    // Atualiza ranking mock
    final userIndex = _mockRanking.indexWhere((r) => r.id == userId);
    if (userIndex != -1) {
      final user = _mockRanking[userIndex];
      _mockRanking[userIndex] = RankingModel(
        id: user.id,
        userName: user.userName,
        totalCheckins: user.totalCheckins + 1,
        position: user.position,
      );
      // Reordena ranking
      _mockRanking.sort((a, b) => b.totalCheckins.compareTo(a.totalCheckins));
      // Atualiza posições
      for (int i = 0; i < _mockRanking.length; i++) {
        _mockRanking[i] = _mockRanking[i].copyWithPosition(i + 1);
      }
    }

    print('✅ [MOCK] Check-in criado: $docId');
    return checkin;
  }

  /// Verifica se o usuário já fez check-in hoje.
  Future<bool> hasCheckinToday(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final today = AppDateUtils.todayKey;
    final docId = '${userId}_$today';

    // TODO: [FIREBASE_REAL] Substitua pelo código abaixo:
    // final doc = await _firestore.collection('checkins').doc(docId).get();
    // return doc.exists;

    return _mockCheckins.containsKey(docId);
  }

  /// Busca o ranking de usuários por total de check-ins.
  ///
  /// Retorna os top [limit] usuários ordenados por constância.
  Future<List<RankingModel>> fetchRanking({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: [FIREBASE_REAL] Substitua pelo código abaixo:
    // final snapshot = await _firestore
    //     .collection('users')
    //     .orderBy('totalCheckins', descending: true)
    //     .limit(limit)
    //     .get();
    //
    // return snapshot.docs
    //     .asMap()
    //     .entries
    //     .map((entry) => RankingModel.fromMap(
    //           entry.value.data(),
    //           entry.value.id,
    //         ).copyWithPosition(entry.key + 1))
    //     .toList();

    return _mockRanking.take(limit).toList();
  }

  /// Busca o histórico de check-ins do usuário.
  ///
  /// Retorna os últimos [limit] check-ins ordenados por data.
  Future<List<CheckinModel>> fetchHistory(
    String userId, {
    int limit = 7,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: [FIREBASE_REAL] Substitua pelo código abaixo:
    // final snapshot = await _firestore
    //     .collection('checkins')
    //     .where('userId', isEqualTo: userId)
    //     .orderBy('date', descending: true)
    //     .limit(limit)
    //     .get();
    //
    // return snapshot.docs
    //     .map((doc) => CheckinModel.fromMap(doc.data()))
    //     .toList();

    // Mock: Gera histórico fictício dos últimos dias
    final mockHistory = <CheckinModel>[];
    final now = DateTime.now();

    // Adiciona check-ins mock para alguns dias passados
    for (int i = 1; i <= limit; i++) {
      // Pula alguns dias para simular constância irregular
      if (i % 3 == 0) continue;

      final date = now.subtract(Duration(days: i));
      mockHistory.add(
        CheckinModel(
          userId: userId,
          date: AppDateUtils.formatToCheckinKey(date),
          createdAt: date,
        ),
      );
    }

    // Adiciona check-ins reais feitos na sessão
    mockHistory.addAll(_mockCheckins.values.where((c) => c.userId == userId));

    // Remove duplicatas e ordena
    final uniqueHistory = <String, CheckinModel>{};
    for (final checkin in mockHistory) {
      uniqueHistory[checkin.date] = checkin;
    }

    final sortedHistory = uniqueHistory.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return sortedHistory.take(limit).toList();
  }

  /// Retorna o total de check-ins do usuário.
  Future<int> getTotalCheckins(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // TODO: [FIREBASE_REAL] Buscar do documento do usuário
    // final doc = await _firestore.collection('users').doc(userId).get();
    // return doc.data()?['totalCheckins'] ?? 0;

    final user = _mockRanking.firstWhere(
      (r) => r.id == userId,
      orElse: () => const RankingModel(id: '', userName: '', totalCheckins: 0),
    );

    return user.totalCheckins;
  }
}
