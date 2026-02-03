/// ============================================================================
/// RANKING MODEL - Modelo de Ranking de Usuários
/// ============================================================================
///
/// Representa um usuário no ranking por constância de leitura.
///
/// O ranking é baseado exclusivamente no número total de dias
/// em que o usuário fez check-in. Não importa livro ou páginas.
///
/// ============================================================================

import 'package:equatable/equatable.dart';

/// Modelo que representa uma entrada no ranking.
///
/// Usado para exibir a classificação dos usuários
/// por total de check-ins realizados.
class RankingModel extends Equatable {
  /// ID do usuário
  final String id;

  /// Nome de exibição do usuário
  final String userName;

  /// Total de check-ins (dias de leitura)
  final int totalCheckins;

  /// Posição no ranking (calculada dinamicamente)
  final int? position;

  const RankingModel({
    required this.id,
    required this.userName,
    required this.totalCheckins,
    this.position,
  });

  /// Cria um RankingModel a partir de um Map (JSON).
  factory RankingModel.fromMap(Map<String, dynamic> map, String id) {
    return RankingModel(
      id: id,
      userName: map['userName'] as String? ?? 'Usuário',
      totalCheckins: map['totalCheckins'] as int? ?? 0,
      position: map['position'] as int?,
    );
  }

  /// Converte o RankingModel para Map (JSON).
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'totalCheckins': totalCheckins,
      if (position != null) 'position': position,
    };
  }

  /// Cria uma cópia com posição atualizada.
  RankingModel copyWithPosition(int newPosition) {
    return RankingModel(
      id: id,
      userName: userName,
      totalCheckins: totalCheckins,
      position: newPosition,
    );
  }

  @override
  List<Object?> get props => [id, userName, totalCheckins, position];

  @override
  String toString() {
    return 'RankingModel(userName: $userName, totalCheckins: $totalCheckins, position: $position)';
  }
}
