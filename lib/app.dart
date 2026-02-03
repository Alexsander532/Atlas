/// ============================================================================
/// APP.DART - Configuração do MaterialApp
/// ============================================================================
///
/// Arquivo central de configuração do aplicativo.
///
/// Contém:
/// - MaterialApp com tema Material 3
/// - Configuração de rotas nomeadas
/// - BlocProviders para gerenciamento de estado
///
/// ARQUITETURA:
/// O app é envolvido pelos BlocProviders que fornecem
/// os Cubits para toda a árvore de widgets.
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/auth_state.dart';
import 'features/auth/pages/forgot_password_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/signup_page.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/services/auth_service.dart';
import 'features/onboarding/pages/onboarding_page.dart';
import 'features/splash/pages/splash_page.dart';
import 'features/dashboard/cubit/dashboard_cubit.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'features/dashboard/repositories/checkin_repository.dart';

/// Widget principal do aplicativo.
///
/// Configura:
/// 1. BlocProviders globais (Auth)
/// 2. Tema Material 3
/// 3. Rotas nomeadas
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Cria instâncias dos services e repositories
    // Em uma app real, use dependency injection (get_it, etc)
    final authService = AuthService();
    final authRepository = AuthRepository(authService);
    final checkinRepository = CheckinRepository();

    return MultiBlocProvider(
      providers: [
        // Provider global de autenticação
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepository)..checkAuthStatus(),
        ),
      ],
      child: MaterialApp(
        // Configurações básicas
        title: 'Atlas',
        debugShowCheckedModeBanner: false,

        // Tema Material 3
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,

        // Rota inicial
        initialRoute: '/splash',

        // Gerador de rotas
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/splash':
              return MaterialPageRoute(
                builder: (_) => const SplashPage(),
                settings: settings,
              );

            case '/login':
              return MaterialPageRoute(
                builder: (_) => const LoginPage(),
                settings: settings,
              );

            case '/forgot-password':
              return MaterialPageRoute(
                builder: (_) => const ForgotPasswordPage(),
                settings: settings,
              );

            case '/signup':
              return MaterialPageRoute(
                builder: (_) => const SignUpPage(),
                settings: settings,
              );

            case '/onboarding':
              return MaterialPageRoute(
                builder: (_) => const OnboardingPage(),
                settings: settings,
              );

            case '/dashboard':
              // Dashboard precisa do usuário autenticado
              return MaterialPageRoute(
                builder: (context) {
                  // Obtém o usuário do AuthCubit
                  final authState = context.read<AuthCubit>().state;

                  if (authState is AuthAuthenticated) {
                    // Cria DashboardCubit com dados do usuário
                    return BlocProvider<DashboardCubit>(
                      create: (context) => DashboardCubit(
                        checkinRepository: checkinRepository,
                        userId: authState.user.id,
                        userName: authState.user.name,
                      ),
                      child: const DashboardPage(),
                    );
                  }

                  // Se não autenticado, volta para login
                  return const LoginPage();
                },
                settings: settings,
              );

            default:
              // Rota não encontrada - vai para login
              return MaterialPageRoute(
                builder: (_) => const LoginPage(),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}
