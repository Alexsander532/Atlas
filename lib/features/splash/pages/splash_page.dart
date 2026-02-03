/// ============================================================================
/// SPLASH PAGE - Tela de Carregamento Inicial
/// ============================================================================
///
/// Tela de splash com animações suaves e elegantes.
/// Exibe o rosto do Atlas centralizado.
/// Transiciona para a tela de login após animação.
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _fadeOut;
  late Animation<Color?> _bgColor;

  bool _isAnimationDone = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimation();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _bgColor = ColorTween(begin: const Color(0xFF13223F), end: Colors.white)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
          ),
        );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isAnimationDone = true);
        _checkNavigation();
      }
    });
  }

  void _startAnimation() {
    _controller.forward();
  }

  void _checkNavigation() {
    if (!mounted || !_isAnimationDone) return;

    final state = context.read<AuthCubit>().state;

    if (state is AuthAuthenticated) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (state is AuthUnauthenticated || state is AuthError) {
      Navigator.pushReplacementNamed(context, '/login');
    }
    // Se estiver Loading ou Initial, aguarda o BlocListener
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        _checkNavigation();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final opacity = _fadeIn.value * _fadeOut.value;

          return Scaffold(
            backgroundColor: _bgColor.value,
            body: Center(
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Image.asset(
                    'assets/images/mascot_face.png',
                    height: 300, // Ajustado para ser responsivo
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
