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

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.createdAt,
  });

  /// Cria um UserModel a partir de um Map (JSON/Firestore).
  ///
  /// Usado para deserializar dados do Firestore ou API.
  /// Suporta tanto Timestamp do Firestore quanto String ISO8601.
  ///
  /// Exemplo de uso com Firestore:
  /// ```dart
  /// final doc = await firestore.collection('users').doc(uid).get();
  /// final user = UserModel.fromMap(doc.data()!, doc.id);
  /// ```
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
      createdAt: createdAt,
    );
  }

  /// Converte o UserModel para Map (JSON).
  ///
  /// Usado para serializar dados para Firestore ou API.
  ///
  /// Exemplo de uso com Firestore:
  /// ```dart
  /// await firestore.collection('users').doc(user.id).set(user.toMap());
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Cria uma cópia do UserModel com campos alterados.
  ///
  /// Útil para atualizar dados imutavelmente.
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Lista de propriedades usadas para comparação de igualdade.
  ///
  /// Equatable usa esta lista para determinar se dois objetos são iguais.
  @override
  List<Object?> get props => [id, email, name, createdAt];

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
  }
}
