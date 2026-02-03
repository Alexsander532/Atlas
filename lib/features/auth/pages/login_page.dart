/// ============================================================================
/// LOGIN PAGE - Tela de Login
/// ============================================================================
///
/// Tela principal de autenticação do aplicativo.
///
/// ESTRUTURA:
/// - AppBar com título
/// - Campo de email
/// - Campo de senha
/// - Botão de login
/// - Link para "Esqueci minha senha"
///
/// ESTADOS TRATADOS:
/// - [AuthLoading]: Exibe loading no botão
/// - [AuthAuthenticated]: Navega para Dashboard
/// - [AuthError]: Exibe SnackBar com erro
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Tela de login do aplicativo.
///
/// Usa [BlocListener] para reagir a mudanças de estado
/// e [BlocBuilder] para reconstruir UI quando necessário.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // Controllers dos campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Key do formulário para validação
  final _formKey = GlobalKey<FormState>();

  // Checkbox para primeiro acesso (onboarding)
  bool _isFirstAccess = false;

  // ====== ANIMAÇÕES DE ENTRADA ======
  late AnimationController _animController;
  late Animation<double> _mascoteFade;
  late Animation<double> _mascoteScale;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _animController.forward();
  }

  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Mascote: fade in + scale (0% - 50%)
    _mascoteFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _mascoteScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Formulário: fade in + slide up (30% - 100%)
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signIn(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  void _onForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  void _onSignUp() {
    Navigator.pushNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Cor de fundo branca como na referência
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (_isFirstAccess) {
              Navigator.pushReplacementNamed(context, '/onboarding');
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          // ====== MASCOTE ======
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _mascoteScale.value,
                                child: Opacity(
                                  opacity: _mascoteFade.value,
                                  child: child,
                                ),
                              );
                            },
                            child: SizedBox(
                              height: 250,
                              child: Transform.scale(
                                scale: 1.6,
                                child: Image.asset(
                                  'assets/images/mascot.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ====== TÍTULO E FORMULÁRIO (com animação) ======
                          SlideTransition(
                            position: _formSlide,
                            child: FadeTransition(
                              opacity: _formFade,
                              child: Column(
                                children: [
                                  // ====== TÍTULO ======
                                  Text(
                                    'Acesse sua conta',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontSize: 28,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),

                                  // ====== CAMPO EMAIL ======
                                  _buildTextField(
                                    controller: _emailController,
                                    hintText: 'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, informe seu email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // ====== CAMPO SENHA ======
                                  // Nota: Usando PasswordTextField customizado ou adaptando aqui.
                                  // Para garantir o visual exato, vamos usar o widget existente mas com estilo ajustado
                                  // ou reconstruir se necessário. Vamos adaptar o existente via Theme ou wrapper.
                                  // Como o design pede algo specific (borda arredondada simples),
                                  // vamos usar o AuthTextField existente mas com override de decoração se possível,
                                  // ou criar uma versão local simplificada para corresponder à imagem.
                                  _PasswordInput(
                                    controller: _passwordController,
                                    onSubmitted: _onLogin,
                                  ),

                                  const SizedBox(height: 16),

                                  // ====== CHECKBOX PRIMEIRO ACESSO ======
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        value: _isFirstAccess,
                                        onChanged: (value) {
                                          setState(() {
                                            _isFirstAccess = value ?? false;
                                          });
                                        },
                                        activeColor: const Color(0xFF0D1B42),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isFirstAccess = !_isFirstAccess;
                                          });
                                        },
                                        child: const Text(
                                          'Primeiro acesso?',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // ====== BOTÃO ENTRAR ======
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: BlocBuilder<AuthCubit, AuthState>(
                                      builder: (context, state) {
                                        final isLoading = state is AuthLoading;
                                        return ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : _onLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0D1B42,
                                            ), // Azul escuro profundo
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    28,
                                                  ), // Borda bem redonda
                                            ),
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Text(
                                                  'Entrar',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // ====== ESQUECI MINHA SENHA ======
                                  TextButton(
                                    onPressed: _onForgotPassword,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF0D1B42),
                                    ),
                                    child: const Text(
                                      'Esqueci minha senha',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 0),

                                  // ====== CRIAR CONTA ======
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Não tem uma conta? ',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        GestureDetector(
                                          onTap: _onSignUp,
                                          child: const Text(
                                            'Criar agora',
                                            style: TextStyle(
                                              color: Colors
                                                  .black, // Ou azul escuro
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// Widget auxiliar local para senha
class _PasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  const _PasswordInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      style: const TextStyle(color: Colors.black),
      onFieldSubmitted: (_) => widget.onSubmitted(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe sua senha';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Senha',
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
