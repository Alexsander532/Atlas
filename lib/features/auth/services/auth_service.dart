/// ============================================================================
/// AUTH SERVICE - Serviço de Autenticação
/// ============================================================================
///
/// Camada de integração com o Firebase Authentication.
///
/// ARQUITETURA:
/// - Service: Comunicação direta com Firebase
/// - Repository: Abstrai o Service para o Cubit
/// - Cubit: Gerencia estados da UI
///
/// FUNCIONALIDADES:
/// - Login com email/senha
/// - Cadastro de novos usuários
/// - Logout
/// - Redefinição de senha por email
/// - Salvar dados do usuário no Firestore
///
/// ============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

/// Exceção customizada para erros de autenticação.
///
/// Encapsula erros do Firebase em uma exceção padronizada para o app.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Serviço de autenticação do aplicativo.
///
/// Responsável pela comunicação direta com o Firebase Auth.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // MÉTODOS DE AUTENTICAÇÃO
  // ============================================================

  /// Realiza login com email e senha.
  ///
  /// Retorna [UserModel] em caso de sucesso.
  /// Lança [AuthException] em caso de erro.
  ///
  /// Exemplo:
  /// ```dart
  /// try {
  ///   final user = await authService.signIn(email, password);
  ///   print('Logado como: ${user.name}');
  /// } on AuthException catch (e) {
  ///   print('Erro: ${e.message}');
  /// }
  /// ```
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    // Validação básica
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException(
        'Email e senha são obrigatórios',
        code: 'invalid-input',
      );
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Erro ao obter usuário');
      }

      // Tenta buscar dados adicionais do Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      String userName = user.displayName ?? '';
      DateTime? createdAt;

      if (userDoc.exists) {
        final data = userDoc.data();
        userName = data?['name'] ?? userName;
        if (data?['createdAt'] != null) {
          createdAt = (data!['createdAt'] as Timestamp).toDate();
        }
      }

      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: userName,
        createdAt: createdAt,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Erro ao realizar login: $e');
    }
  }

  /// Realiza cadastro de novo usuário.
  ///
  /// Cria o usuário no Firebase Auth e salva dados no Firestore.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // Validação básica
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw const AuthException(
        'Todos os campos são obrigatórios',
        code: 'invalid-input',
      );
    }

    try {
      // Cria usuário no Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Erro ao criar usuário');
      }

      // Atualiza o displayName no Firebase Auth
      await user.updateDisplayName(name);

      // Define role: admin se for o email específico, senão member
      final isAdmin =
          email.toLowerCase() == 'alexsanderaugusto142019@gmail.com';
      final role = isAdmin ? 'admin' : 'member';

      // Salva dados adicionais no Firestore
      final now = DateTime.now();
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': Timestamp.fromDate(now),
        'currentStreak': 0,
        'maxStreak': 0,
        'totalCheckins': 0,
        'lastCheckinDate': null, // Nunca fez check-in
      });

      return UserModel(id: user.uid, email: email, name: name, createdAt: now);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Erro ao criar conta: $e');
    }
  }

  /// Realiza logout do usuário atual.
  ///
  /// Limpa o estado de autenticação.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Erro ao sair: $e');
    }
  }

  /// Envia email de redefinição de senha.
  ///
  /// Lança [AuthException] se o email não estiver cadastrado.
  Future<void> resetPassword({required String email}) async {
    if (email.isEmpty) {
      throw const AuthException('Email é obrigatório', code: 'invalid-email');
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code), code: e.code);
    } catch (e) {
      throw AuthException('Erro ao enviar email: $e');
    }
  }

  /// Retorna o usuário atualmente autenticado.
  ///
  /// Retorna null se não houver usuário logado.
  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
    );
  }

  /// Verifica se há um usuário autenticado.
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Stream de mudanças no estado de autenticação.
  ///
  /// Útil para reagir a login/logout em tempo real.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ============================================================
  // HELPERS
  // ============================================================

  /// Traduz códigos de erro do Firebase para mensagens amigáveis.
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuário desativado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'email-already-in-use':
        return 'Este email já está cadastrado';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'invalid-credential':
        return 'Email ou senha incorretos';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet';
      default:
        return 'Erro de autenticação. Tente novamente';
    }
  }
}
