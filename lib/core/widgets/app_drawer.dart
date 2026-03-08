import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/cubit/auth_state.dart';
import '../../features/groups/services/group_service.dart';
import '../../features/groups/models/group_model.dart';
import '../../features/groups/pages/create_group_page.dart';
import '../../features/groups/pages/join_group_page.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final GroupService _groupService = GroupService();
  List<GroupModel> _userGroups = [];
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final groups = await _groupService.getUserGroups(authState.user.id);
      if (mounted) {
        setState(() {
          _userGroups = groups;
          _isLoadingGroups = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    final user = authState.user;
    final hasActiveGroup = user.activeGroupId != null &&
        _userGroups.any((g) => g.id == user.activeGroupId);
    final isProfileActive = !hasActiveGroup;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header: Pill with user info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  if (!isProfileActive) {
                    context.read<AuthCubit>().clearActiveGroup();
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isProfileActive
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isProfileActive
                            ? Colors.white
                            : colorScheme.primary.withValues(alpha: 0.15),
                        foregroundColor: colorScheme.primary,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isProfileActive
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Menu Items (Grupos + Itens Fixos)
            Expanded(
              child: _isLoadingGroups
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        // Meus Grupos (se houver)
                        if (_userGroups.isNotEmpty) ...[
                          ..._userGroups.map((group) {
                            final isActive = user.activeGroupId == group.id;
                            return _buildDrawerItem(
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: isActive
                                    ? Colors.white
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                child: Text(
                                  group.name.isNotEmpty
                                      ? group.name[0].toUpperCase()
                                      : 'G',
                                  style: TextStyle(
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: group.name,
                              isActive: isActive,
                              onTap: () {
                                context.read<AuthCubit>().updateActiveGroup(
                                  group.id,
                                );
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dashboard',
                                );
                              },
                            );
                          }),
                          const Divider(height: 16),
                        ],

                        // Itens Estáticos Originais
                        _buildDrawerItem(
                          icon: Icons.star_border,
                          title: 'Obter Pro',
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDrawerItem(
                          icon: Icons.add_circle_outline,
                          title: 'Criar grupo',
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateGroupPage(),
                              ),
                            ).then((_) => _loadGroups());
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.group_add_outlined,
                          title: 'Juntar-se ao grupo',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JoinGroupPage(),
                              ),
                            ).then((_) => _loadGroups());
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildDrawerItem(
                          icon: Icons.outlined_flag,
                          title: 'Desafios concluídos',
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDrawerItem(
                          icon: Icons.settings_outlined,
                          title: 'Configurações',
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.help_outline,
                          title: 'Ajuda & feedback',
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    IconData? icon,
    Widget? leading,
    required String title,
    required VoidCallback onTap,
    Color? backgroundColor,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final activeBgColor = theme.colorScheme.primary.withValues(alpha: 0.15);
    final activeTextColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? activeBgColor
                : (backgroundColor ?? Colors.transparent),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              leading ??
                  Icon(
                    icon,
                    color: isActive ? activeTextColor : Colors.black87,
                    size: 26,
                  ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isActive ? activeTextColor : Colors.black87,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
