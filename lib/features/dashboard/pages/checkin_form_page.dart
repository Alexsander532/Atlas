/// ============================================================================
/// CHECKIN FORM PAGE - Formulário de Check-in
/// ============================================================================
///
/// Tela para registrar um novo check-in de leitura.
/// Campos: Título (obrigatório), Descrição (opcional), Foto (obrigatória)
///
/// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/checkin_service.dart';

/// Página do formulário de check-in.
class CheckinFormPage extends StatefulWidget {
  final String userId;
  final String userName;
  final VoidCallback? onSuccess;

  const CheckinFormPage({
    super.key,
    required this.userId,
    required this.userName,
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
  String? _imageName;
  bool _isLoading = false;
  String? _errorMessage;

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
          // Web: usa bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _imageName = pickedFile.name;
            _errorMessage = null;
          });
        } else {
          // Mobile: usa File
          setState(() {
            _imageFile = File(pickedFile.path);
            _imageName = pickedFile.name;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar imagem: $e';
      });
    }
  }

  /// Mostra opções de fonte da imagem.
  void _showImageSourceOptions() {
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

  /// Envia o check-in.
  Future<void> _submitCheckin() async {
    // Valida formulário
    if (!_formKey.currentState!.validate()) return;

    // Foto agora é opcional / em breve
    // if (_imageFile == null && _imageBytes == null) { ... }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      );

      if (mounted) {
        // Mostra sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in registrado com sucesso! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Callback de sucesso
        widget.onSuccess?.call();

        // Fecha a página
        Navigator.pop(context, true);
      }
    } on CheckinException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao registrar check-in: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Leitura')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ====== SAUDAÇÃO ======
              Text(
                'O que você leu hoje? 📖',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registre sua leitura para manter sua sequência!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // ====== CAMPO TÍTULO ======
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ex: Capítulo 5 - A Jornada',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 16),

              // ====== CAMPO DESCRIÇÃO ======
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Conte um pouco sobre o que leu...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ====== SELETOR DE FOTO (OPCIONAL/EM BREVE) ======
              Row(
                children: [
                  Text(
                    'Foto da leitura (opcional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Em breve',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Preview da imagem ou botão de adicionar
              Opacity(
                opacity: 0.6, // Indica que é "em breve" ou secundário
                child: GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    height: 150, // Menor que antes
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.5),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: _buildImagePreview(colorScheme),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              const SizedBox(height: 24),

              // ====== MENSAGEM DE ERRO ======
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // ====== BOTÃO ENVIAR ======
              FilledButton.icon(
                onPressed: _isLoading ? null : _submitCheckin,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? 'Enviando...' : 'Confirmar Leitura'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o preview da imagem ou placeholder.
  Widget _buildImagePreview(ColorScheme colorScheme) {
    if (_imageBytes != null) {
      // Web: mostra a partir dos bytes
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_imageBytes!, fit: BoxFit.cover),
            _buildImageOverlay(colorScheme),
          ],
        ),
      );
    } else if (_imageFile != null) {
      // Mobile: mostra a partir do arquivo
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_imageFile!, fit: BoxFit.cover),
            _buildImageOverlay(colorScheme),
          ],
        ),
      );
    } else {
      // Placeholder
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 48,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicionar foto (Opcional)',
            style: TextStyle(
              color: colorScheme.primary.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  /// Overlay com botão de trocar imagem.
  Widget _buildImageOverlay(ColorScheme colorScheme) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 16, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'Trocar',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
