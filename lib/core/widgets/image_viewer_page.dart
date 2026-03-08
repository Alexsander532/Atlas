import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Página para visualização de imagem com zoom.
class ImageViewerPage extends StatelessWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String tag; // Para Hero animation

  const ImageViewerPage({
    super.key,
    this.imageFile,
    this.imageBytes,
    this.imageUrl,
    this.tag = 'image_viewer',
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (imageBytes != null) {
      imageProvider = MemoryImage(imageBytes!);
    } else if (imageFile != null) {
      imageProvider = FileImage(imageFile!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: imageProvider == null
            ? const Text(
                'Imagem indisponível',
                style: TextStyle(color: Colors.white),
              )
            : Hero(
                tag: tag,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image(image: imageProvider, fit: BoxFit.contain),
                ),
              ),
      ),
    );
  }
}
