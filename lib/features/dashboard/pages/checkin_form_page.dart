/// ============================================================================
/// CHECKIN FORM PAGE - Formulário de Check-in
/// ============================================================================
///
/// Tela para registrar um novo check-in de leitura com o novo design de cards.
///
/// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/checkin_service.dart';

/// Página do formulário de check-in.
class CheckinFormPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String groupId;
  final VoidCallback? onSuccess;

  const CheckinFormPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.groupId,
    this.onSuccess,
  });

  @override
  State<CheckinFormPage> createState() => _CheckinFormPageState();
}

class _CheckinFormPageState extends State<CheckinFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _checkinService = CheckinService();
  final _imagePicker = ImagePicker();

  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  // Controle de destino do checkin
  bool _publishToProfile = true;
  bool _publishToGroup = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Seleciona uma imagem da galeria ou câmera.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageBytes = bytes;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  /// Mostra opções de fonte da imagem.
  void _showImageSourceOptions() {
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
                'Adicionar foto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupSelectionModal() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selecionar grupo e perfil',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escolha onde publicar este check-in.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Profile Switch
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Visível no seu perfil.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _publishToProfile,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            setModalState(() => _publishToProfile = val);
                            setState(() => _publishToProfile = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Group Switch
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.group, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Grupo Principal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Switch(
                          value: _publishToGroup,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            setModalState(() => _publishToGroup = val);
                            setState(() => _publishToGroup = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Envia o check-in.
  Future<void> _submitCheckin() async {
    if (!_formKey.currentState!.validate()) return;

    // Se nenhum switch ativado, avisa
    if (!_publishToProfile && !_publishToGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um destino para o check-in'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _checkinService.performCheckin(
        userId: widget.userId,
        userName: widget.userName,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        imageFile: _imageFile,
        imageBytes: _imageBytes,
        groupId: _publishToGroup ? widget.groupId : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in publicado! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSuccess?.call();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar check-in: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF7F9FA);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Novo check-in',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _submitCheckin,
                  child: Text(
                    'Publicar',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ====== TOP HEADER: IMAGE AND STATUS ======
              _buildHeaderVisualArea(),

              const SizedBox(height: 32),

              // ====== FORM BLOCKS ======
              // Título e Descrição
              _buildWhiteContainer(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Título do check-in',
                        hintStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'O título é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 1),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Conte um pouco sobre o que você leu...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Dia e Hora (Placeholder visual)
              Row(
                children: [
                  Expanded(
                    child: _buildWhiteContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dia',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(DateTime.now()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildWhiteContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hora de início',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(DateTime.now()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.access_time,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Localização
              _buildWhiteContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 12),
                      const Text('Localização', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Text('Nenhum', style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderVisualArea() {
    int groupsCount = (_publishToGroup ? 1 : 0) + (_publishToProfile ? 0 : 0);
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Esquerda: Seleção de destino
        Expanded(
          child: GestureDetector(
            onTap: _showGroupSelectionModal,
            child: Column(
              children: [
                SizedBox(
                  width: 50,
                  height: 30,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(
                            Icons.group,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Em $groupsCount grupo, perfil',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        // Centro: Imagem principal
        GestureDetector(
          onTap: _showImageSourceOptions,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 140,
                height: 180,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _hasImage()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildImagePreviewWidget(),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicionar foto',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
              ),
              Positioned(
                bottom: -15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Direita: Validade
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Válido',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasImage() => _imageFile != null || _imageBytes != null;

  Widget _buildImagePreviewWidget() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }

  Widget _buildWhiteContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
