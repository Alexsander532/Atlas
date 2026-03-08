/// ============================================================================
/// PROFILE PAGE - Página de Perfil
/// ============================================================================
///
/// Exibe informações do usuário e estatísticas de leitura.
/// Permite edição de foto de perfil.
/// Algumas estatísticas (como horas) são ilustrativas/mock por enquanto.
///
/// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../services/checkin_service.dart';
import '../../../core/widgets/image_viewer_page.dart';
import '../models/checkin_model.dart';
import 'checkin_form_page.dart';
import 'checkin_detail_page.dart';
import '../../../core/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Página de perfil do usuário.
class ProfilePage extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? photoUrl;

  const ProfilePage({super.key, this.userId, this.userName, this.photoUrl});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final CheckinService _checkinService = CheckinService();
  final ImagePicker _imagePicker = ImagePicker();

  int _totalCheckins = 0;
  bool _isLoadingStats = true;
  bool _isUploadingPhoto = false;

  // Check-ins reais para marcar no calendário
  Map<DateTime, CheckinModel> _checkinEvents = {};
  DateTime _focusedDay = DateTime.now();

  String? _otherUserName;
  String? _otherPhotoUrl;

  bool get _isCurrentUser {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      return widget.userId == null || widget.userId == authState.user.id;
    }
    return false;
  }

  String get _targetUserId {
    if (widget.userId != null) return widget.userId!;
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return '';
  }

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final targetId = _targetUserId;
    if (targetId.isEmpty) {
      if (mounted) setState(() => _isLoadingStats = false);
      return;
    }

    // Busca infomações adicionais se não for o usuário logado
    if (!_isCurrentUser) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _otherUserName = data['name'];
            _otherPhotoUrl = data['photoUrl'];
          });
        }
      } catch (e) {
        debugPrint('Erro ao buscar dados do perfil: $e');
      }
    }

    final score = await _checkinService.getUserScore(
      targetId,
      groupId: null, // Busca pontuação global
    );

    if (mounted) {
      setState(() {
        _totalCheckins = score;
        _isLoadingStats = false;
      });

      // Carregar os check-ins do mes focado (globais)
      await _loadCheckinsForMonth(_focusedDay, targetId);
    }
  }

  Future<void> _loadCheckinsForMonth(DateTime month, String userId) async {
    try {
      final mapStr = await _checkinService.getCheckinMapByMonth(
        month.year,
        month.month,
        userId: userId,
        groupId: null, // Busca global
      );

      final Map<DateTime, CheckinModel> newMap = {};
      for (final entry in mapStr.entries) {
        final parts = entry.key.split('-'); // ex: 2026-03-07
        if (parts.length == 3) {
          final date = DateTime.utc(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          newMap[date] = entry.value;
        }
      }

      if (mounted) {
        setState(() {
          _checkinEvents = newMap;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar checkins do calendario: $e');
    }
  }

  Future<void> _pickAndUploadImage(String source) async {
    try {
      final ImageSource imageSource = source == 'camera'
          ? ImageSource.camera
          : ImageSource.gallery;

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: imageSource,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      File? imageFile;
      Uint8List? imageBytes;

      if (kIsWeb) {
        imageBytes = await pickedFile.readAsBytes();
      } else {
        imageFile = File(pickedFile.path);
      }

      if (mounted) {
        await context.read<AuthCubit>().updateProfilePhoto(
          imageFile: imageFile,
          imageBytes: imageBytes,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil atualizada! 📸'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Opções de Conta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage('camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher foto da galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage('gallery');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sair da conta',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(String? photoUrl) {
    if (photoUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageViewerPage(imageUrl: photoUrl, tag: 'profile_photo'),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = const Color(0xFFF7F9FA);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;

        final int activeDaysCount = _totalCheckins;

        return Scaffold(
          backgroundColor: backgroundColor,
          drawer: _isCurrentUser ? const AppDrawer() : null,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            leading: _isCurrentUser
                ? Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.sort, color: Colors.black87),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
            actions: [
              if (_isCurrentUser)
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.black87,
                  ),
                  onPressed: _showSettingsMenu,
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadUserStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  _buildProfileHeader(user, theme, colorScheme),
                  const SizedBox(height: 24),
                  if (_isLoadingStats)
                    const CircularProgressIndicator()
                  else
                    _buildStatsRow(
                      _totalCheckins,
                      activeDaysCount,
                      theme,
                    ),
                  const SizedBox(height: 24),
                  if (_isCurrentUser) ...[
                    _buildActionChipsRow(theme),
                    const SizedBox(height: 32),
                  ],
                  _buildCalendarSection(theme),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          floatingActionButton: _isCurrentUser
              ? FloatingActionButton(
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckinFormPage(
                          userId: user.id,
                          userName: user.name,
                          groupId: user.activeGroupId ?? '',
                          onSuccess: _loadUserStats,
                        ),
                      ),
                    );
                  },
                )
              : null,
        );
      },
    );
  }

  Widget _buildProfileHeader(
    dynamic user,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final displayName = !_isCurrentUser
        ? (_otherUserName ?? widget.userName ?? 'Usuário')
        : user.name;
    final displayPhoto = !_isCurrentUser
        ? (_otherPhotoUrl ?? widget.photoUrl)
        : user.photoUrl;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _openImageViewer(displayPhoto),
          child: Hero(
            tag: 'profile_photo_${widget.userId ?? "me"}',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    image: displayPhoto != null && displayPhoto.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(displayPhoto),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: displayPhoto == null || displayPhoto.isEmpty
                      ? Center(
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                if (_isUploadingPhoto)
                  const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    int checkins,
    int diasAtivos,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactStat(checkins.toString(), 'Check-ins', theme),
        _buildCompactStat(diasAtivos.toString(), 'Dias ativos', theme),
      ],
    );
  }

  Widget _buildCompactStat(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildActionChipsRow(ThemeData theme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildChipIcon(Icons.military_tech_outlined, 'Melhore', theme),
        _buildChipIcon(Icons.bolt_outlined, 'Stats', theme),
        _buildChipIcon(Icons.track_changes_outlined, 'Metas', theme),
      ],
    );
  }

  Widget _buildChipIcon(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(ThemeData theme) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final dateKey = DateTime.utc(date.year, date.month, date.day);
                if (_checkinEvents.containsKey(dateKey)) {
                  final checkin = _checkinEvents[dateKey]!;
                  if (checkin.imageUrl != null) {
                    return Positioned(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(checkin.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Positioned(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }
                return null;
              },
            ),
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
              _loadCheckinsForMonth(focusedDay, _targetUserId);
            },
            onDaySelected: (selectedDay, focusedDay) {
              final dateKey = DateTime.utc(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              if (_checkinEvents.containsKey(dateKey)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CheckinDetailPage(checkin: _checkinEvents[dateKey]!),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
