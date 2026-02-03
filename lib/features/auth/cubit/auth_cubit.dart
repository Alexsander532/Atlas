/// ============================================================================
/// AUTH CUBIT - Controlador de Estado de Autenticação
/// ============================================================================
///
/// Gerencia o estado de autenticação do aplicativo.
///
/// RESPONSABILIDADES:
/// - Gerenciar estados de login/logout
/// - Validar inputs antes de chamar o repository
/// - Emitir estados apropriados para a UI
/// - NÃO acessar Services diretamente (apenas Repository)
///
/// ARQUITETURA:
/// ```
/// UI (Page) ← Cubit ← Repository ← Service ← Firebase
/// ```
///
/// USO:
/// ```dart
/// // Na UI
/// context.read<AuthCubit>().signIn(email, password);
///
/// // Com BlocProvider
/// BlocProvider(
///   create: (context) => AuthCubit(authRepository),
///   child: LoginPage(),
/// )
/// ```
///
/// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

/// Cubit responsável pelo gerenciamento de autenticação.
///
/// Recebe comandos da UI e emite estados apropriados
/// com base nas respostas do [AuthRepository].
class AuthCubit extends Cubit<AuthState> {
  /// Repositório de autenticação.
  ///
  /// Injetado via construtor para facilitar testes.
  final AuthRepository _authRepository;

  /// Construtor que recebe o repositório de autenticação.
  ///
  /// Inicia com estado [AuthInitial].
  AuthCubit(this._authRepository) : super(const AuthInitial());

  // ============================================================
  // MÉTODOS PÚBLICOS
  // ============================================================

  /// Realiza login com email e senha.
  ///
  /// Fluxo:
  /// 1. Valida inputs
  /// 2. Emite [AuthLoading]
  /// 3. Chama repository.signIn()
  /// 4. Emite [AuthAuthenticated] ou [AuthError]
  ///
  /// Exemplo de uso na UI:
  /// ```dart
  /// onPressed: () {
  ///   context.read<AuthCubit>().signIn(
  ///     _emailController.text,
  ///     _passwordController.text,
  ///   );
  /// }
  /// ```
  Future<void> signIn(String email, String password) async {
    // Validação de inputs
    if (email.trim().isEmpty) {
      emit(const AuthError('Por favor, informe seu email'));
      return;
    }

    if (password.isEmpty) {
      emit(const AuthError('Por favor, informe sua senha'));
      return;
    }

    // Validação simples de formato de email
    if (!_isValidEmail(email)) {
      emit(const AuthError('Por favor, informe um email válido'));
      return;
    }

    // Inicia loading
    emit(const AuthLoading());

    try {
      // Chama o repository (NUNCA o service diretamente!)
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );

      // Sucesso: emite estado autenticado
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      // Erro conhecido: emite com mensagem traduzida
      emit(AuthError(e.message, code: e.code));
    } catch (e) {
      // Erro desconhecido: emite mensagem genérica
      emit(const AuthError('Erro ao realizar login. Tente novamente.'));
    }
  }

  /// Realiza cadastro de novo usuário.
  Future<void> signUp(String name, String email, String password) async {
    if (name.trim().isEmpty) {
      emit(const AuthError('Por favor, informe seu nome'));
      return;
    }

    if (email.trim().isEmpty) {
      emit(const AuthError('Por favor, informe seu email'));
      return;
    }

    if (password.isEmpty) {
      emit(const AuthError('Por favor, informe uma senha'));
      return;
    }

    if (!_isValidEmail(email)) {
      emit(const AuthError('Por favor, informe um email válido'));
      return;
    }

    emit(const AuthLoading());

    try {
      final user = await _authRepository.signUp(
        name: name,
        email: email,
        password: password,
      );

      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message, code: e.code));
    } catch (e) {
      emit(const AuthError('Erro ao realizar cadastro. Tente novamente.'));
    }
  }

  /// Realiza logout do usuário atual.
  ///
  /// Fluxo:
  /// 1. Emite [AuthLoading]
  /// 2. Chama repository.signOut()
  /// 3. Emite [AuthUnauthenticated]
  Future<void> signOut() async {
    emit(const AuthLoading());

    try {
      await _authRepository.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(const AuthError('Erro ao sair. Tente novamente.'));
    }
  }

  /// Envia email de redefinição de senha.
  ///
  /// Fluxo:
  /// 1. Valida email
  /// 2. Emite [AuthLoading]
  /// 3. Chama repository.resetPassword()
  /// 4. Emite [AuthPasswordResetSent] ou [AuthError]
  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      emit(const AuthError('Por favor, informe seu email'));
      return;
    }

    if (!_isValidEmail(email)) {
      emit(const AuthError('Por favor, informe um email válido'));
      return;
    }

    emit(const AuthLoading());

    try {
      await _authRepository.resetPassword(email: email);
      emit(AuthPasswordResetSent(email.trim().toLowerCase()));
    } on AuthException catch (e) {
      emit(AuthError(e.message, code: e.code));
    } catch (e) {
      emit(const AuthError('Erro ao enviar email. Tente novamente.'));
    }
  }

  /// Reinicia o estado para inicial.
  ///
  /// Útil para limpar erros e permitir nova tentativa.
  void resetState() {
    emit(const AuthInitial());
  }

  // ============================================================
  // HELPERS PRIVADOS
  // ============================================================

  /// Valida formato básico de email.
  ///
  /// Verifica se contém @ e pelo menos um ponto após @.
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }
}
