/// ============================================================================
/// LOADING INDICATOR - Indicador de Carregamento
/// ============================================================================
///
/// Widget reutilizável para exibir estados de carregamento.
///
/// Oferece duas variantes:
/// - [LoadingIndicator]: Indicador centralizado em tela cheia
/// - [LoadingOverlay]: Overlay que cobre o conteúdo durante loading
///
/// Uso:
/// ```dart
/// // Tela de loading
/// if (state is Loading) {
///   return const LoadingIndicator();
/// }
///
/// // Overlay sobre conteúdo
/// LoadingOverlay(
///   isLoading: _isLoading,
///   child: MyContent(),
/// )
/// ```
/// ============================================================================

import 'package:flutter/material.dart';

/// Indicador de carregamento centralizado.
///
/// Exibe um CircularProgressIndicator no centro da área disponível.
/// Ideal para telas que estão totalmente em estado de loading.
class LoadingIndicator extends StatelessWidget {
  /// Mensagem opcional exibida abaixo do indicador
  final String? message;

  /// Cor do indicador (usa cor primária do tema se null)
  final Color? color;

  const LoadingIndicator({super.key, this.message, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador circular
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? colorScheme.primary,
            ),
          ),
          // Mensagem opcional
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay de carregamento que cobre o conteúdo.
///
/// Útil quando você quer manter o conteúdo visível,
/// mas impedir interações durante uma operação assíncrona.
class LoadingOverlay extends StatelessWidget {
  /// Widget filho que será coberto pelo overlay
  final Widget child;

  /// Se true, exibe o overlay de loading
  final bool isLoading;

  /// Mensagem exibida no overlay
  final String? message;

  /// Opacidade do overlay (0.0 a 1.0)
  final double overlayOpacity;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.overlayOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Conteúdo principal
        child,

        // Overlay condicional
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: overlayOpacity),
              child: LoadingIndicator(message: message),
            ),
          ),
      ],
    );
  }
}

/// Shimmer placeholder para loading de conteúdo.
///
/// Útil para skeleton screens enquanto dados carregam.
class ShimmerPlaceholder extends StatefulWidget {
  /// Largura do placeholder
  final double width;

  /// Altura do placeholder
  final double height;

  /// Raio do border radius
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                colorScheme.surfaceContainerHighest,
              ],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}
