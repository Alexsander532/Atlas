/// ============================================================================
/// CHECKIN MODEL - Modelo de Check-in de Leitura
/// ============================================================================
///
/// Representa um check-in de leitura diário do usuário.
///
/// REGRAS DE NEGÓCIO:
/// - Apenas 1 check-in por dia por usuário
/// - O [date] é no formato yyyy-MM-dd para garantir unicidade
/// - O documentId no Firestore será: {userId}_{date}
///
/// ============================================================================

import 'package:equatable/equatable.dart';

/// Modelo que representa um check-in de leitura.
///
/// Cada check-in indica que o usuário leu no dia especificado.
/// Não importa quantas páginas ou qual livro, apenas a constância.
class CheckinModel extends Equatable {
  /// ID do usuário que fez o check-in
  final String userId;

  /// Data do check-in no formato yyyy-MM-dd.
  ///
  /// Este formato garante:
  /// - Unicidade por dia
  /// - Ordenação correta
  /// - Compatibilidade com Firestore
  final String date;

  /// Timestamp de quando o check-in foi criado.
  ///
  /// Usado para ordenação exata dentro do dia.
  final DateTime createdAt;

  const CheckinModel({
    required this.userId,
    required this.date,
    required this.createdAt,
  });

  /// Gera o ID do documento para Firestore.
  ///
  /// Formato: {userId}_{date}
  /// Exemplo: "user_001_2024-01-15"
  ///
  /// Isso garante que cada usuário tenha apenas
  /// um documento por dia (unicidade natural).
  String get documentId => '${userId}_$date';

  /// Cria um CheckinModel a partir de um Map (JSON).
  ///
  /// Usado para deserializar dados do Firestore.
  factory CheckinModel.fromMap(Map<String, dynamic> map) {
    return CheckinModel(
      userId: map['userId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Converte o CheckinModel para Map (JSON).
  ///
  /// Usado para serializar dados para Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Lista de propriedades para comparação de igualdade.
  @override
  List<Object?> get props => [userId, date, createdAt];

  @override
  String toString() {
    return 'CheckinModel(userId: $userId, date: $date)';
  }
}
