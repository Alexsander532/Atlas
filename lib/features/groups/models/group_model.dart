/// ============================================================================
/// GROUP MODEL - Modelo de Grupo/Desafio
/// ============================================================================
///
/// Representa um grupo/desafio de leitura com duração fixa.
///
/// Cada grupo tem:
/// - Nome e descrição
/// - Duração em dias (definida pelo criador)
/// - Data de início e fim
/// - Código de convite único
/// - Lista de membros
///
/// Pontuação: 1 check-in por dia = 1 ponto (máx 1/dia)
///
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Modelo que representa um grupo/desafio.
class GroupModel extends Equatable {
  /// ID do documento Firestore.
  final String id;

  /// Nome do grupo/desafio.
  final String name;

  /// Descrição opcional.
  final String? description;

  /// URL da imagem/ícone do grupo.
  final String? imageUrl;

  /// ID do criador (admin do grupo).
  final String createdBy;

  /// Data de criação.
  final DateTime createdAt;

  /// Data de início do desafio.
  final DateTime startDate;

  /// Data de fim do desafio.
  final DateTime endDate;

  /// Duração em dias do desafio.
  final int durationDays;

  /// Código único de convite (ex: ATLAS-XK7M).
  final String inviteCode;

  /// IDs dos membros do grupo.
  final List<String> memberIds;

  /// Contador de membros.
  final int memberCount;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.inviteCode,
    required this.memberIds,
    required this.memberCount,
  });

  /// Verifica se o desafio ainda está ativo.
  bool get isActive {
    final now = DateTime.now();
    final endOfDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );
    return now.isBefore(endOfDay) || now.isAtSameMomentAs(endOfDay);
  }

  /// Dias restantes do desafio.
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = end.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Dias decorridos do desafio.
  int get daysElapsed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final diff = today.difference(start).inDays;
    if (diff < 0) return 0;
    return diff > durationDays ? durationDays : diff;
  }

  /// Cria a partir de um documento Firestore.
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : DateTime.now(),
      durationDays: data['durationDays'] ?? 30,
      inviteCode: data['inviteCode'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberCount: data['memberCount'] ?? 0,
    );
  }

  /// Converte para Map para salvar no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'durationDays': durationDays,
      'inviteCode': inviteCode,
      'memberIds': memberIds,
      'memberCount': memberCount,
    };
  }

  /// Cria uma cópia com campos alterados.
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    String? inviteCode,
    List<String>? memberIds,
    int? memberCount,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      inviteCode: inviteCode ?? this.inviteCode,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  List<Object?> get props => [id, name, inviteCode, memberCount, durationDays];

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, members: $memberCount, '
        'duration: $durationDays days, active: $isActive)';
  }
}
