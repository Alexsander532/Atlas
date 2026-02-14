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

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../services/checkin_service.dart';
import '../services/ranking_service.dart';
import 'checkin_form_page.dart';
import '../../chat/pages/chat_page.dart';
import 'history_page.dart';

import 'profile_page.dart';
import '../../groups/services/group_service.dart';
import '../../groups/models/group_model.dart';
import '../../groups/widgets/invite_share_widget.dart';

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

        final group = await _groupService.getGroupById(widget.groupId);

        if (mounted) {
          setState(() {
            _hasCheckedInToday = hasChecked;
            _userScore = userScore;
            _ranking = ranking;
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
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Início',
    ),
    NavigationItem(
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
      label: 'Ranking',
    ),
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    NavigationItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Histórico',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  /// Abre o formulário de check-in.
  void _openCheckinForm() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckinFormPage(
          userId: authState.user.id,
          userName: authState.user.name,
          groupId: widget.groupId,
          onSuccess: () {
            _loadData(); // Recarrega os dados após check-in
          },
        ),
      ),
    );
  }

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
        title: const Text('Atlas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildPageContent(),
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
                      CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          color: colorScheme.onPrimaryContainer,
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
        return 'Chat';
      case 3:
        return 'Histórico';
      case 4:
        return 'Perfil';
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
      case 3:
        return HistoryPage(groupId: widget.groupId);
      case 4:
        return const ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  /// Conteúdo da página inicial (Home).
  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.read<AuthCubit>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.name
        : 'Usuário';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Lógica de saudação
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Bom dia';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Boa tarde';
    } else {
      greeting = 'Boa noite';
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ====== SAUDAÇÃO ======
            Text(
              '$greeting, $userName! 👋',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Continue sua sequência de leitura!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // ====== CONVITE DO GRUPO ======
            if (_activeGroup != null) ...[
              InviteShareWidget(
                inviteCode: _activeGroup!.inviteCode,
                groupName: _activeGroup!.name,
              ),
              const SizedBox(height: 24),
            ],

            // ====== CARD DE CHECK-IN ======
            _buildCheckinCard(theme, colorScheme),
            const SizedBox(height: 16),

            // ====== ESTATÍSTICAS RÁPIDAS ======
            _buildStatsRow(theme, colorScheme),
            const SizedBox(height: 16),

            // ====== MINI RANKING ======
            _buildMiniRanking(theme, colorScheme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: _hasCheckedInToday
          ? colorScheme.primaryContainer.withOpacity(0.5)
          : colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _hasCheckedInToday ? Icons.check_circle : Icons.menu_book,
              size: 48,
              color: _hasCheckedInToday
                  ? Colors.green
                  : colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              _hasCheckedInToday
                  ? 'Leitura confirmada hoje! ✅'
                  : 'Registre sua leitura de hoje',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasCheckedInToday
                  ? 'Continue assim! Sua sequência está crescendo.'
                  : 'Clique abaixo para manter sua sequência',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            if (!_hasCheckedInToday)
              FilledButton.icon(
                onPressed: _openCheckinForm,
                icon: const Icon(Icons.add),
                label: const Text('Confirmar Leitura'),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Você já registrou sua leitura hoje! 🎉'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Ver meu check-in'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            value: '$_userScore',
            label: 'Pontos',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            value: '$_userScore',
            label: 'Check-ins',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniRanking(ThemeData theme, ColorScheme colorScheme) {
    final topRanking = _ranking.take(5).toList();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Top 5 Ranking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (topRanking.isEmpty)
              const Center(child: Text('Nenhum participante ainda'))
            else
              ...topRanking.map((item) => _buildRankingTile(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingTile(RankingItem item) {
    final authState = context.read<AuthCubit>().state;
    final isCurrentUser =
        authState is AuthAuthenticated && authState.user.id == item.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildPositionBadge(item.position),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                '${item.totalCheckins}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ranking.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '🏆 Ranking de Leitura',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final item = _ranking[index - 1];
          final authState = context.read<AuthCubit>().state;
          final isCurrentUser =
              authState is AuthAuthenticated && authState.user.id == item.id;

          return Card(
            elevation: 0,
            color: isCurrentUser
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: _buildPositionBadge(item.position),
              title: Text(
                item.name,
                style: TextStyle(
                  fontWeight: isCurrentUser
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: Text('Total: ${item.totalCheckins} check-ins'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${item.totalCheckins}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
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
