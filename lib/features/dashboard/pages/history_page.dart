/// ============================================================================
/// HISTORY PAGE - Página de Histórico
/// ============================================================================
///
/// Exibe um calendário visual com fotos dos check-ins.
/// Permite alternar entre "Meu Histórico" e "Todos".
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/photo_calendar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../models/checkin_model.dart';
import '../services/checkin_service.dart';
import 'checkin_detail_page.dart';

/// Página de histórico com calendário visual.
class HistoryPage extends StatefulWidget {
  final String groupId;

  const HistoryPage({super.key, required this.groupId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final CheckinService _checkinService = CheckinService();

  DateTime _currentMonth = DateTime.now();
  bool _showOnlyMine = true;
  bool _isLoading = true;
  Map<String, CheckinModel> _checkinMap = {};

  @override
  void initState() {
    super.initState();
    _loadCheckins();
  }

  Future<void> _loadCheckins() async {
    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthCubit>().state;
      String? userId;

      if (_showOnlyMine && authState is AuthAuthenticated) {
        userId = authState.user.id;
      }

      final map = await _checkinService.getCheckinMapByMonth(
        _currentMonth.year,
        _currentMonth.month,
        userId: userId,
        groupId: widget.groupId,
      );

      if (mounted) {
        setState(() {
          _checkinMap = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar histórico: $e')),
        );
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
    _loadCheckins();
  }

  void _toggleView(bool showMine) {
    if (_showOnlyMine != showMine) {
      setState(() => _showOnlyMine = showMine);
      _loadCheckins();
    }
  }

  void _openCheckinDetail(CheckinModel checkin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckinDetailPage(checkin: checkin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Nome do mês em português
    final monthName = DateFormat.yMMMM('pt_BR').format(_currentMonth);

    return RefreshIndicator(
      onRefresh: _loadCheckins,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: Navegação de mês
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  monthName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle: Meu / Todos
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      label: 'Meu Histórico',
                      isSelected: _showOnlyMine,
                      onTap: () => _toggleView(true),
                      colorScheme: colorScheme,
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      label: 'Todos',
                      isSelected: !_showOnlyMine,
                      onTap: () => _toggleView(false),
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Estatística rápida
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isLoading
                        ? 'Carregando...'
                        : '${_checkinMap.length} leitura(s) em ${DateFormat.MMMM('pt_BR').format(_currentMonth)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calendário
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else
              PhotoCalendar(
                year: _currentMonth.year,
                month: _currentMonth.month,
                checkinsByDate: _checkinMap,
                onDayTap: _openCheckinDetail,
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
