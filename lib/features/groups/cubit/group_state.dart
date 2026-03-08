/// ============================================================================
/// GROUP STATE - Estados do GroupCubit
/// ============================================================================

import 'package:equatable/equatable.dart';
import '../models/group_model.dart';

/// Estado base do GroupCubit.
abstract class GroupState extends Equatable {
  const GroupState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial.
class GroupInitial extends GroupState {
  const GroupInitial();
}

/// Carregando grupos.
class GroupLoading extends GroupState {
  const GroupLoading();
}

/// Grupos carregados com sucesso.
class GroupsLoaded extends GroupState {
  /// Lista de grupos do usuário.
  final List<GroupModel> groups;

  /// Grupo atualmente selecionado (ativo).
  final GroupModel? activeGroup;

  const GroupsLoaded({required this.groups, this.activeGroup});

  @override
  List<Object?> get props => [groups, activeGroup];
}

/// Entrando em um grupo (via código).
class GroupJoining extends GroupState {
  const GroupJoining();
}

/// Entrou no grupo com sucesso.
class GroupJoined extends GroupState {
  final GroupModel group;

  const GroupJoined(this.group);

  @override
  List<Object?> get props => [group];
}

/// Criando grupo.
class GroupCreating extends GroupState {
  const GroupCreating();
}

/// Grupo criado com sucesso.
class GroupCreated extends GroupState {
  final GroupModel group;

  const GroupCreated(this.group);

  @override
  List<Object?> get props => [group];
}

/// Erro no grupo.
class GroupError extends GroupState {
  final String message;

  const GroupError(this.message);

  @override
  List<Object?> get props => [message];
}
