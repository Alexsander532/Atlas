/// ============================================================================
/// AUTH REPOSITORY - Repositório de Autenticação
/// ============================================================================
///
/// Camada de abstração entre o Cubit e o Service.
///
/// RESPONSABILIDADES:
/// - Abstrair detalhes de implementação do Service
/// - Aplicar regras de negócio simples
/// - Facilitar testes com mocks
/// - Padronizar interface para o Cubit
///
/// ARQUITETURA:
/// ```
/// Cubit → Repository → Service → Firebase
/// ```
///
/// O Cubit NUNCA deve acessar o Service diretamente.
/// Isso mantém a separação de responsabilidades.
///
/// ============================================================================

import 'dart:io';
import 'dart:typed_data';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Repositório de autenticação.
///
/// Fornece uma interface limpa para operações de autenticação,
/// abstraindo os detalhes do [AuthService].
class AuthRepository {
  /// Instância do serviço de autenticação.
  ///
  /// Injetada via construtor para facilitar testes.
  final AuthService _authService;

  /// Construtor que recebe o serviço de autenticação.
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final authService = AuthService();
  /// final authRepository = AuthRepository(authService);
  /// ```
  ///
  /// Para testes, pode-se injetar um mock:
  /// ```dart
  /// final mockService = MockAuthService();
  /// final authRepository = AuthRepository(mockService);
  /// ```
  AuthRepository(this._authService);

  // ============================================================
  // MÉTODOS PÚBLICOS
  // ============================================================

  /// Realiza login com email e senha.
  ///
  /// Delega para o [AuthService] e retorna o [UserModel].
  ///
  /// Lança [AuthException] em caso de erro.
  Future<UserModel> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    // Remove espaços e converte para minúsculas
    final normalizedEmail = email.trim().toLowerCase();

    return await _authService.signIn(
      email: normalizedEmail,
      password: password,
      rememberMe: rememberMe,
    );
  }

  /// Recarrega dados do usuário atual.
  Future<UserModel?> reloadUser() async {
    return await _authService.reloadUser();
  }

  /// Realiza cadastro de novo usuário.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    return await _authService.signUp(
      name: name.trim(),
      email: normalizedEmail,
      password: password,
    );
  }

  /// Realiza logout do usuário atual.
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Envia email de redefinição de senha.
  ///
  /// Lança [AuthException] se o email não estiver cadastrado.
  Future<void> resetPassword({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();

    await _authService.resetPassword(email: normalizedEmail);
  }

  /// Retorna o usuário atualmente autenticado.
  ///
  /// Retorna null se não houver usuário logado.
  UserModel? get currentUser => _authService.currentUser;

  /// Atualiza a foto de perfil.
  Future<UserModel> updateProfilePhoto({
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    return await _authService.updateProfilePhoto(
      imageFile: imageFile,
      imageBytes: imageBytes,
    );
  }

  /// Verifica se há um usuário autenticado.
  bool get isAuthenticated => _authService.isAuthenticated;
}
