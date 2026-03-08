/// ============================================================================
/// PRIMARY BUTTON - Botão Principal Reutilizável
/// ============================================================================
///
/// Widget de botão reutilizável com suporte a:
/// - Estado de carregamento (loading)
/// - Estado desabilitado
/// - Ícone opcional
/// - Largura total ou automática
///
/// Uso:
/// ```dart
/// PrimaryButton(
///   text: 'Entrar',
///   onPressed: () => doSomething(),
///   isLoading: _isLoading,
/// )
/// ```
/// ============================================================================

import 'package:flutter/material.dart';

/// Botão principal customizado do aplicativo.
///
/// Este widget encapsula a lógica comum de botões,
/// incluindo estados de loading e disabled.
class PrimaryButton extends StatelessWidget {
  /// Texto exibido no botão
  final String text;

  /// Callback executado ao pressionar o botão.
  /// Se null, o botão fica desabilitado.
  final VoidCallback? onPressed;

  /// Indica se o botão está em estado de carregamento.
  /// Quando true, exibe um CircularProgressIndicator.
  final bool isLoading;

  /// Ícone opcional exibido antes do texto
  final IconData? icon;

  /// Se true, o botão ocupa toda a largura disponível
  final bool fullWidth;

  /// Cor de fundo customizada (opcional)
  /// Se null, usa a cor primária do tema
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Obtém o ColorScheme do tema atual
    final colorScheme = Theme.of(context).colorScheme;

    // Conteúdo do botão: loading indicator ou texto/ícone
    final Widget buttonContent = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone opcional
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              // Texto do botão
              Text(text),
            ],
          );

    // Botão com estilo elevado
    final button = ElevatedButton(
      // Desabilita se estiver carregando ou se onPressed for null
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        // Garante altura mínima confortável para toque
        minimumSize: const Size(0, 52),
      ),
      child: buttonContent,
    );

    // Retorna com largura total ou automática
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

/// Botão secundário (outlined) para ações menos importantes.
///
/// Uso para ações como "Cancelar" ou navegação secundária.
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Widget buttonContent = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: buttonContent,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
