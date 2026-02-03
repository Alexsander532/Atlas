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

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimation();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Reduzido de 2500
    );

    // Fade in suave
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Scale suave
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    // Fade out rápido (80% - 100% do tempo = 400ms)
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    // Cor de fundo saindo (80% - 100% do tempo)
    _bgColor = ColorTween(begin: const Color(0xFF13223F), end: Colors.white)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
          ),
        );
  }

  void _startAnimation() async {
    await _controller.forward();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Combinar fade in e fade out
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
                  height: 1000,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
