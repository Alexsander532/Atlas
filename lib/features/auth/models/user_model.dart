/// ============================================================================
/// USER MODEL - Modelo de Usuário
/// ============================================================================
///
/// Representa um usuário autenticado no sistema.
///
/// Este modelo é simples e focado apenas nos dados necessários
/// para identificação do usuário no contexto de check-ins.
///
/// PREPARAÇÃO PARA FIREBASE:
/// - O [id] corresponde ao uid do FirebaseAuth
/// - O [email] vem do User.email do FirebaseAuth
/// - O [name] pode ser obtido do displayName ou do Firestore
///
/// ============================================================================

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um usuário do aplicativo.
///
/// Estende [Equatable] para facilitar comparações de estado
/// no BLoC, evitando rebuilds desnecessários.
class UserModel extends Equatable {
  /// Identificador único do usuário.
  ///
  /// No Firebase, corresponde ao `uid` do FirebaseAuth.
  final String id;

  /// Email do usuário.
  ///
  /// Usado para login e identificação.
  final String email;

  /// Nome de exibição do usuário.
  ///
  /// Usado no ranking e em saudações.
  final String name;

  /// Data de criação da conta.
  ///
  /// Útil para estatísticas e ordenação.
  final DateTime? createdAt;

  /// URL da foto de perfil.
  final String? photoUrl;

  /// ID do grupo atualmente ativo/selecionado.
  final String? activeGroupId;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.createdAt,
    this.photoUrl,
    this.activeGroupId,
  });

  /// Cria um UserModel a partir de um Map (JSON/Firestore).
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? createdAt;

    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        createdAt = DateTime.parse(map['createdAt'] as String);
      }
    }

    return UserModel(
      id: id,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      createdAt: createdAt,
      activeGroupId: map['activeGroupId'] as String?,
    );
  }

  /// Converte o UserModel para Map (JSON).
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'activeGroupId': activeGroupId,
    };
  }

  /// Cria uma cópia do UserModel com campos alterados.
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    DateTime? createdAt,
    String? activeGroupId,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      activeGroupId: activeGroupId ?? this.activeGroupId,
    );
  }

  /// Lista de propriedades usadas para comparação de igualdade.
  ///
  /// Equatable usa esta lista para determinar se dois objetos são iguais.
  @override
  List<Object?> get props => [
    id,
    email,
    name,
    photoUrl,
    createdAt,
    activeGroupId,
  ];

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
  }
}
