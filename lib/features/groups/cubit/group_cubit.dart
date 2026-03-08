/// ============================================================================
/// GROUP CUBIT - Controlador de Estado dos Grupos
/// ============================================================================
///
/// Gerencia o estado dos grupos/desafios:
/// - Listar grupos do usuário
/// - Criar novo grupo
/// - Entrar em grupo via código
/// - Selecionar grupo ativo
///
/// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/group_repository.dart';
import '../models/group_model.dart';
import 'group_state.dart';

/// Cubit responsável pelo gerenciamento dos grupos.
class GroupCubit extends Cubit<GroupState> {
  final GroupRepository _groupRepository;
  final String _userId;

  GroupCubit({required GroupRepository groupRepository, required String userId})
    : _groupRepository = groupRepository,
      _userId = userId,
      super(const GroupInitial());

  // ============================================================
  // MÉTODOS PÚBLICOS
  // ============================================================

  /// Carrega os grupos do usuário.
  Future<void> loadGroups({String? activeGroupId}) async {
    emit(const GroupLoading());

    try {
      final groups = await _groupRepository.getUserGroups(_userId);

      GroupModel? activeGroup;
      if (activeGroupId != null && activeGroupId.isNotEmpty) {
        try {
          activeGroup = groups.firstWhere((g) => g.id == activeGroupId);
        } catch (_) {
          // activeGroupId não encontrado na lista, tenta buscar direto
          activeGroup = await _groupRepository.getGroupById(activeGroupId);
        }
      }

      emit(GroupsLoaded(groups: groups, activeGroup: activeGroup));
    } catch (e) {
      emit(GroupError('Erro ao carregar grupos: $e'));
    }
  }

  /// Cria um novo grupo/desafio.
  Future<void> createGroup({
    required String name,
    String? description,
    required int durationDays,
  }) async {
    emit(const GroupCreating());

    try {
      final group = await _groupRepository.createGroup(
        name: name,
        description: description,
        durationDays: durationDays,
        creatorId: _userId,
      );

      emit(GroupCreated(group));
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  /// Entra em um grupo pelo código de convite.
  Future<void> joinGroup(String inviteCode) async {
    emit(const GroupJoining());

    try {
      final group = await _groupRepository.joinGroupByCode(
        inviteCode: inviteCode,
        userId: _userId,
      );

      emit(GroupJoined(group));
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  /// Busca preview do grupo pelo código (sem entrar).
  Future<GroupModel?> previewGroup(String inviteCode) async {
    try {
      return await _groupRepository.getGroupByCode(inviteCode);
    } catch (_) {
      return null;
    }
  }

  /// Seleciona um grupo como ativo.
  Future<void> selectGroup(GroupModel group) async {
    try {
      await _groupRepository.setActiveGroup(userId: _userId, groupId: group.id);

      // Recarrega com o novo grupo ativo
      final groups = await _groupRepository.getUserGroups(_userId);
      emit(GroupsLoaded(groups: groups, activeGroup: group));
    } catch (e) {
      emit(GroupError('Erro ao selecionar grupo: $e'));
    }
  }

  /// Sai de um grupo.
  Future<void> leaveGroup(String groupId) async {
    try {
      await _groupRepository.leaveGroup(groupId: groupId, userId: _userId);

      // Recarrega a lista
      await loadGroups();
    } catch (e) {
      emit(GroupError('Erro ao sair do grupo: $e'));
    }
  }
}
