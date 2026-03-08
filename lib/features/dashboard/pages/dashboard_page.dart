/// ============================================================================
/// DASHBOARD PAGE - Tela Principal do Aplicativo (Responsiva)
/// ============================================================================
///
/// Tela principal após o login, com layout adaptativo:
/// - Mobile: BottomNavigationBar (4 abas)
/// - Web/Desktop: NavigationRail lateral com hover para expandir
///
/// Abas: Início, Ranking, Chat, Perfil
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../services/checkin_service.dart';
import '../services/ranking_service.dart';
import '../../chat/pages/chat_page.dart';
import '../../../core/widgets/app_drawer.dart';
import '../widgets/challenge_hero_card.dart';
import '../widgets/checkin_timeline_item.dart';
import 'challenge_details_page.dart';
import 'profile_page.dart';
import '../../groups/services/group_service.dart';
import '../../groups/models/group_model.dart';
import '../models/checkin_model.dart';

/// Página principal do Dashboard.
class DashboardPage extends StatefulWidget {
  final String groupId;

  const DashboardPage({super.key, required this.groupId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Índice da página selecionada no menu
  int _selectedIndex = 0;

  // Controla se a barra lateral está expandida (hover no desktop)
  bool _isRailExpanded = false;

  // Breakpoint para trocar de layout
  static const double _breakpoint = 800;

  // Serviços
  final CheckinService _checkinService = CheckinService();

  final RankingService _rankingService = RankingService();
  final GroupService _groupService = GroupService();

  // Dados
  bool _hasCheckedInToday = false;
  int _userScore = 0;
  List<RankingItem> _ranking = [];
  List<CheckinModel> _recentCheckins = [];
  GroupModel? _activeGroup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      try {
        final hasChecked = await _checkinService.hasCheckedInToday(
          authState.user.id,
          groupId: widget.groupId,
        );
        final userScore = await _checkinService.getUserScore(
          authState.user.id,
          groupId: widget.groupId,
        );
        final ranking = await _rankingService.getRanking(
          groupId: widget.groupId,
          limit: 20,
        );

        final checkins = await _checkinService.getRecentCheckins(
          groupId: widget.groupId,
          limit: 30,
        );

        final group = await _groupService.getGroupById(widget.groupId);

        if (mounted) {
          setState(() {
            _hasCheckedInToday = hasChecked;
            _userScore = userScore;
            _ranking = ranking;
            _recentCheckins = checkins;
            _activeGroup = group;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
        }
      }
    }
  }

  /// Itens do menu de navegação
  List<NavigationItem> get _navigationItems => [
    NavigationItem(
      icon: Icons.list_alt_rounded,
      selectedIcon: Icons.list_alt_rounded,
      label: 'Detalhes',
    ),
    NavigationItem(
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
      label: 'Classificações',
    ),
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: 'Bate-papo',
    ),
  ];

  /// Realiza o logout.
  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().signOut();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  /// Muda a página selecionada.
  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated || state is AuthInitial) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < _breakpoint;

          if (isMobile) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  /// Layout para dispositivos móveis com BottomNavigationBar.
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          _activeGroup?.name ?? 'Carregando...',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              // TODO: Notificações
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (value) {
              if (value == 'invite') {
                // TODO: Convidar
              } else if (value == 'leave') {
                // TODO: Sair do grupo
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'invite',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Convidar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'notifications',
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Configurações de notificação'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Deixar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildPageContent(),
      drawer: const AppDrawer(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _navigationItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Layout para desktop/web com NavigationRail lateral.
  Widget _buildDesktopLayout() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // ====== BARRA LATERAL ======
          MouseRegion(
            onEnter: (_) => setState(() => _isRailExpanded = true),
            onExit: (_) => setState(() => _isRailExpanded = false),
            child: NavigationRail(
              extended: _isRailExpanded,
              minWidth: 72,
              minExtendedWidth: 200,
              backgroundColor: colorScheme.surfaceContainerLow,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              leading: Column(
                children: [
                  const SizedBox(height: 8),
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isRailExpanded ? Icons.menu_open : Icons.menu,
                        key: ValueKey(_isRailExpanded),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isRailExpanded = !_isRailExpanded;
                      });
                    },
                    tooltip: _isRailExpanded
                        ? 'Recolher menu'
                        : 'Expandir menu',
                  ),
                  const SizedBox(height: 16),
                  // Título Animado "Atlas"
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    height: 30,
                    width: _isRailExpanded ? 100 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isRailExpanded ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Atlas',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize:
                    MainAxisSize.min, // Importante para evitar erro de layout
                children: [
                  const Divider(),
                  _RailMenuButton(
                    icon: Icons.refresh,
                    label: 'Atualizar',
                    onPressed: _loadData,
                    expanded: _isRailExpanded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  _RailMenuButton(
                    icon: Icons.logout,
                    label: 'Sair',
                    onPressed: _onLogout,
                    expanded: _isRailExpanded,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              destinations: _navigationItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // ====== CONTEÚDO PRINCIPAL ======
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getPageTitle(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildPageContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Início';
      case 1:
        return 'Ranking';
      case 2:
        return 'Bate-papo';
      default:
        return 'Atlas';
    }
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildRankingContent();
      case 2:
        return ChatPage(groupId: widget.groupId);
      default:
        return _buildHomeContent();
    }
  }

  /// Conteúdo da página inicial (Home/Feed).
  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : '';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeGroup == null) {
      return const Center(child: Text('Nenhum grupo ativo selecionado.'));
    }

    // Pega o líder do ranking
    final leader = _ranking.isNotEmpty ? _ranking.first : null;

    // Agrupa check-ins por data
    final Map<String, List<CheckinModel>> groupedCheckins = {};
    for (var checkin in _recentCheckins) {
      final date = _formatGroupDate(checkin.createdAt);
      if (!groupedCheckins.containsKey(date)) {
        groupedCheckins[date] = [];
      }
      groupedCheckins[date]!.add(checkin);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ====== CHALLENGE HERO CARD ======
          ChallengeHeroCard(
            group: _activeGroup!,
            leaderName: leader?.name,
            leaderScore: leader?.totalCheckins ?? 0,
            userScore: _userScore,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeDetailsPage(
                    group: _activeGroup!,
                    ranking: _ranking,
                    currentUserId: userId,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Feed do Grupo',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ====== FEED DE CHECK-INS AGRUPADO ======
          if (_recentCheckins.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Nenhum check-in realizado ainda.')),
            )
          else
            ...groupedCheckins.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: Center(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  ...entry.value.map(
                    (checkin) => CheckinTimelineItem(
                      checkin: checkin,
                      isCurrentUser: checkin.userId == userId,
                    ),
                  ),
                ],
              );
            }),

          const SizedBox(height: 80), // Espaço para o FAB
        ],
      ),
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkinDate = DateTime(date.year, date.month, date.day);

    if (checkinDate == today) {
      return 'Hoje';
    } else if (checkinDate == yesterday) {
      return 'Ontem';
    } else {
      return DateFormat("EEEE, MMM d", "pt_BR").format(date).toLowerCase();
    }
  }

  Widget _buildPositionBadge(int position) {
    Color color;
    IconData? icon;

    switch (position) {
      case 1:
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey[400]!;
        icon = Icons.emoji_events;
        break;
      case 3:
        color = Colors.brown[300]!;
        icon = Icons.emoji_events;
        break;
      default:
        color = Colors.grey[300]!;
        icon = null;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 16, color: Colors.white)
            : Text(
                '$position',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  /// Conteúdo da página de Ranking completo.
  Widget _buildRankingContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _ranking.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 56),
        itemBuilder: (context, index) {
          final item = _ranking[index];
          final authState = context.read<AuthCubit>().state;
          final isCurrentUser =
              authState is AuthAuthenticated && authState.user.id == item.id;

          return ListTile(
            leading: _buildPositionBadge(item.position),
            title: Text(
              item.name,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text('${item.totalCheckins} check-ins realizados'),
            trailing: Text(
              '${item.totalCheckins}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    userId: item.id,
                    userName: item.name,
                    photoUrl: item.photoUrl,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Botão customizado para o rodapé do NavigationRail
class _RailMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool expanded;
  final Color? color;

  const _RailMenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.expanded,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 56, // Altura similar aos itens do rail
        padding: const EdgeInsets.symmetric(horizontal: 16),
        width: expanded ? 200 : 72, // Largura animada
        alignment: Alignment.centerLeft, // Alinhamento consistente
        child: Row(
          mainAxisSize: MainAxisSize.min, // Ocupa o necessário
          children: [
            // Ícone sempre visível
            SizedBox(width: 40, child: Icon(icon, color: color, size: 24)),

            // Texto animado com Clip e Opacidade
            Flexible(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: expanded ? 1.0 : 0.0,
                curve: Curves.easeInOut,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modelo auxiliar para itens de navegação.
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
