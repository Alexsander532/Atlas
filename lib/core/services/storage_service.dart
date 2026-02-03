/// ============================================================================
/// STORAGE SERVICE - Serviço de Upload de Arquivos
/// ============================================================================
///
/// Gerencia o upload de imagens para o Firebase Storage.
///
/// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Serviço para upload de arquivos no Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Faz upload de uma imagem de check-in.
  ///
  /// [userId] - ID do usuário
  /// [imageFile] - Arquivo da imagem (mobile)
  /// [imageBytes] - Bytes da imagem (web)
  /// [fileName] - Nome do arquivo (opcional)
  ///
  /// Retorna a URL pública da imagem.
  Future<String> uploadCheckinImage({
    required String userId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    if (imageFile == null && imageBytes == null) {
      throw Exception('Nenhuma imagem fornecida');
    }

    // Gera nome único para o arquivo
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = fileName ?? 'checkin_$timestamp.jpg';

    // Caminho no Storage: checkins/{userId}/{nome}
    final ref = _storage.ref().child('checkins/$userId/$name');

    UploadTask uploadTask;

    if (kIsWeb) {
      // Upload para Web usando bytes
      if (imageBytes == null) {
        throw Exception('Bytes da imagem necessários para web');
      }
      uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else {
      // Upload para Mobile usando File
      if (imageFile == null) {
        throw Exception('Arquivo da imagem necessário para mobile');
      }
      uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    }

    // Aguarda o upload completar
    final snapshot = await uploadTask;

    // Retorna a URL de download
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Deleta uma imagem do Storage.
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignora erros de deleção (imagem pode não existir)
      print('Erro ao deletar imagem: $e');
    }
  }
}
