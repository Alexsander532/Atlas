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

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../../../core/services/migration_service.dart'; // Import migração corrigido
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

  /// Verifica o status atual de autenticação.
  ///
  /// Chamado na inicialização do app para restaurar sessão.
  Future<void> checkAuthStatus() async {
    try {
      final user = await _authRepository.reloadUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
        // Trigger migration check
        MigrationService().runIfNeeded();
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

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
  ///     rememberMe: _rememberMe,
  ///   );
  /// }
  /// ```
  Future<void> signIn(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
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
        rememberMe: rememberMe,
      );

      // Sucesso: emite estado autenticado
      emit(AuthAuthenticated(user));

      // Trigger migration check (now that we have permissions)
      MigrationService().runIfNeeded();
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

      // Trigger migration check
      MigrationService().runIfNeeded();
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

  /// Atualiza a foto de perfil.
  Future<void> updateProfilePhoto({
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    // Mantém o estado atual se possível, ou emite loading
    // Idealmente, poderíamos ter um estado AuthUpdatingProfile, mas AuthLoading serve
    // Se quisermos não bloquear a UI inteira, teríamos que gerenciar o loading localmente na Page.
    // Como o Cubit controla o estado global, o loading aqui pode afetar tudo.
    // Vamos assumir que a Page gerencia o feedback visual de loading específico,
    // mas chamaremos o Cubit para a op.
    // PORÉM, o Cubit emite estados. Se emitirmos AuthLoading, a tela de perfil pode recarregar.

    try {
      final updatedUser = await _authRepository.updateProfilePhoto(
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      emit(AuthAuthenticated(updatedUser));
    } on AuthException catch (e) {
      emit(AuthError(e.message, code: e.code));
    } catch (e) {
      emit(const AuthError('Erro ao atualizar foto.'));
    }
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
