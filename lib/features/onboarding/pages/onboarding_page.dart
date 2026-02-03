/// ============================================================================
/// ONBOARDING PAGE - Telas de Introdução ao App
/// ============================================================================
///
/// Fluxo de onboarding para novos usuários (primeiro acesso).
/// Contém 4 slides explicando as funcionalidades do app.
///
/// ============================================================================

import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Dados das 4 telas de onboarding
  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/images/mascot_onboarding.png',
      'title': 'Acompanhe sua Leitura',
      'description':
          'Registre seus livros, páginas lidas e crie o hábito de ler todos os dias.',
    },
    {
      'image': 'assets/images/mascot_onboarding2.png',
      'title': 'Defina Metas e Desafios',
      'description':
          'Estabeleça metas diárias, semanais ou anuais e desafie-se a ler mais.',
    },
    {
      'image': 'assets/images/mascot_onboarding3.png',
      'title': 'Descubra e Conquiste',
      'description':
          'Explore sua biblioteca, ganhe conquistas e veja seu progresso com o Atlas!',
    },
    {
      'image': 'assets/images/mascot_onboarding4.png',
      'title': 'Participe da Comunidade',
      'description':
          'Conecte-se com outros leitores e compartilhe suas descobertas literárias.',
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Última página: ir para o dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ====== PAGEVIEW ======
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingSlide(_onboardingData[index]);
                },
              ),
            ),

            // ====== INDICADORES (DOTS) ======
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF0D1B42)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ====== BOTÃO PRÓXIMO / COMEÇAR ======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B42),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _currentPage == _onboardingData.length - 1
                        ? 'Começar'
                        : 'Próximo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // ====== INDICADOR DE PÁGINA ======
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '${_currentPage + 1} of ${_onboardingData.length}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingSlide(Map<String, String> data) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ====== MASCOTE ======
              SizedBox(
                height: 200, // Reduzido de 280 para evitar overflow
                child: Transform.scale(
                  scale: 1.7,
                  child: Image.asset(data['image']!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 80),

              // ====== TÍTULO ======
              Text(
                data['title']!,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // ====== DESCRIÇÃO ======
              Text(
                data['description']!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
