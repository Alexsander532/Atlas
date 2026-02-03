/// ============================================================================
/// AUTH TEXT FIELD - Campo de Texto para Autenticação
/// ============================================================================
///
/// Widget de TextField customizado para formulários de autenticação.
///
/// FUNCIONALIDADES:
/// - Toggle de visibilidade para campos de senha
/// - Ícones de prefixo e sufixo
/// - Validação integrada
/// - Estilo consistente com o tema
///
/// ============================================================================

import 'package:flutter/material.dart';

/// Campo de texto customizado para formulários de autenticação.
///
/// Fornece uma interface consistente para campos de email e senha,
/// com suporte a toggle de visibilidade em senhas.
class AuthTextField extends StatefulWidget {
  /// Controller do campo de texto
  final TextEditingController controller;

  /// Texto exibido quando o campo está vazio
  final String hintText;

  /// Rótulo do campo
  final String? labelText;

  /// Ícone exibido à esquerda do campo
  final IconData? prefixIcon;

  /// Se true, obscurece o texto (para senhas)
  final bool obscureText;

  /// Tipo de teclado (email, texto, etc)
  final TextInputType keyboardType;

  /// Ação do teclado (próximo, enviar, etc)
  final TextInputAction textInputAction;

  /// Callback executado ao submeter
  final VoidCallback? onSubmitted;

  /// Função de validação
  final String? Function(String?)? validator;

  /// Se true, faz autofocus quando o widget é montado
  final bool autofocus;

  /// Se true, habilita ícone de toggle de visibilidade
  /// (apenas quando obscureText é true)
  final bool enableVisibilityToggle;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
    this.enableVisibilityToggle = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  /// Controla a visibilidade do texto em campos de senha
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  /// Alterna a visibilidade do texto
  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofocus: widget.autofocus,
      validator: widget.validator,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,

        // Ícone de prefixo (ex: email, cadeado)
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: colorScheme.onSurfaceVariant)
            : null,

        // Ícone de sufixo (toggle de visibilidade para senhas)
        suffixIcon: widget.obscureText && widget.enableVisibilityToggle
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: _toggleVisibility,
                tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
              )
            : null,
      ),
    );
  }
}

/// Campo de email pré-configurado.
///
/// Atalho para AuthTextField com configurações de email.
class EmailTextField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;
  final String? Function(String?)? validator;
  final bool autofocus;

  const EmailTextField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      hintText: 'seu@email.com',
      labelText: 'Email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
      validator: validator,
      autofocus: autofocus,
    );
  }
}

/// Campo de senha pré-configurado.
///
/// Atalho para AuthTextField com configurações de senha.
class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;
  final String? Function(String?)? validator;
  final String? labelText;
  final String? hintText;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.validator,
    this.labelText = 'Senha',
    this.hintText = '••••••',
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      hintText: hintText!,
      labelText: labelText,
      prefixIcon: Icons.lock_outline,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      validator: validator,
    );
  }
}
