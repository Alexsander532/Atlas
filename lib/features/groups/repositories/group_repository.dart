/// ============================================================================
/// GROUP REPOSITORY - Repositório de Grupos
/// ============================================================================
///
/// Abstração entre o Cubit e o GroupService.
///
/// ============================================================================

import '../models/group_model.dart';
import '../services/group_service.dart';

/// Repositório de grupos.
class GroupRepository {
  final GroupService _groupService;

  GroupRepository({GroupService? groupService})
    : _groupService = groupService ?? GroupService();

  /// Cria um novo grupo/desafio.
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required int durationDays,
    required String creatorId,
  }) async {
    return await _groupService.createGroup(
      name: name,
      description: description,
      durationDays: durationDays,
      creatorId: creatorId,
    );
  }

  /// Entra em um grupo pelo código de convite.
  Future<GroupModel> joinGroupByCode({
    required String inviteCode,
    required String userId,
  }) async {
    return await _groupService.joinGroupByCode(
      inviteCode: inviteCode,
      userId: userId,
    );
  }

  /// Busca preview do grupo pelo código (sem entrar).
  Future<GroupModel?> getGroupByCode(String inviteCode) async {
    return await _groupService.getGroupByCode(inviteCode);
  }

  /// Busca grupo por ID.
  Future<GroupModel?> getGroupById(String groupId) async {
    return await _groupService.getGroupById(groupId);
  }

  /// Lista grupos do usuário.
  Future<List<GroupModel>> getUserGroups(String userId) async {
    return await _groupService.getUserGroups(userId);
  }

  /// Stream de grupos do usuário.
  Stream<List<GroupModel>> watchUserGroups(String userId) {
    return _groupService.watchUserGroups(userId);
  }

  /// Busca scores dos membros do grupo.
  Future<List<Map<String, dynamic>>> getMemberScores(String groupId) async {
    return await _groupService.getMemberScores(groupId);
  }

  /// Sai de um grupo.
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    return await _groupService.leaveGroup(groupId: groupId, userId: userId);
  }

  /// Remove membro (admin).
  Future<void> removeMember({
    required String groupId,
    required String memberId,
    required String adminId,
  }) async {
    return await _groupService.removeMember(
      groupId: groupId,
      memberId: memberId,
      adminId: adminId,
    );
  }

  /// Gera novo código de convite.
  Future<String> regenerateInviteCode(String groupId) async {
    return await _groupService.regenerateInviteCode(groupId);
  }

  /// Define o grupo ativo do usuário.
  Future<void> setActiveGroup({
    required String userId,
    required String groupId,
  }) async {
    return await _groupService.setActiveGroup(userId: userId, groupId: groupId);
  }
}
