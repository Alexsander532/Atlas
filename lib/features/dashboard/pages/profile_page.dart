/// ============================================================================
/// PROFILE PAGE - Página de Perfil
/// ============================================================================
///
/// Exibe informações do usuário e estatísticas de leitura.
/// Permite edição de foto de perfil.
///
/// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../services/checkin_service.dart';
import '../../../core/widgets/image_viewer_page.dart';

/// Página de perfil do usuário.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final CheckinService _checkinService = CheckinService();
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _streakData;
  bool _isLoadingStats = true;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final data = await _checkinService.getUserStreakData(authState.user.id);
      if (mounted) {
        setState(() {
          _streakData = data;
          _isLoadingStats = false;
        });
      }
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

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage('gallery');
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

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = state.user;

        return RefreshIndicator(
          onRefresh: _loadStreakData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ====== HEADER / AVATAR ======
                Center(
                  child: Stack(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () => _openImageViewer(user.photoUrl),
                        child: Hero(
                          tag: 'profile_photo',
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: theme.textTheme.displayMedium
                                        ?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  )
                                : null,
                          ),
                        ),
                      ),

                      // Loading Overlay
                      if (_isUploadingPhoto)
                        const Positioned.fill(
                          child: CircularProgressIndicator(),
                        ),

                      // Edit Button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: colorScheme.primary,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            onTap: _showImageOptions,
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ====== NOME ======
                Text(
                  user.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // ====== EMAIL ======
                Text(
                  user.email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // ====== ESTATÍSTICAS ======
                if (_isLoadingStats)
                  const CircularProgressIndicator()
                else if (_streakData != null)
                  _buildStatsSection(theme, colorScheme),

                const SizedBox(height: 32),

                // ====== AÇÕES ======
                _buildActionsSection(colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suas Estatísticas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  value: '${_streakData!['currentStreak']}',
                  label: 'Sequência\nAtual',
                  color: Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.emoji_events,
                  value: '${_streakData!['maxStreak']}',
                  label: 'Maior\nSequência',
                  color: Colors.amber,
                ),
                _buildStatItem(
                  icon: Icons.check_circle,
                  value: '${_streakData!['totalCheckins']}',
                  label: 'Total de\nCheck-ins',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionsSection(ColorScheme colorScheme) {
    return Column(
      children: [
        // Botão de sair
        OutlinedButton.icon(
          onPressed: _onLogout,
          icon: Icon(Icons.logout, color: colorScheme.error),
          label: Text(
            'Sair da conta',
            style: TextStyle(color: colorScheme.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.error),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
