/// ============================================================================
/// AUTH STATE - Estados de Autenticação
/// ============================================================================
///
/// Define todos os estados possíveis do fluxo de autenticação.
///
/// ESTADOS:
/// - [AuthInitial]: Estado inicial, antes de qualquer operação
/// - [AuthLoading]: Operação em andamento (login, logout, etc)
/// - [AuthAuthenticated]: Usuário autenticado com sucesso
/// - [AuthPasswordResetSent]: Email de redefinição enviado
/// - [AuthError]: Erro durante operação
///
/// USO COM BLOC:
/// ```dart
/// BlocBuilder<AuthCubit, AuthState>(
///   builder: (context, state) {
///     if (state is AuthLoading) {
///       return LoadingIndicator();
///     }
///     if (state is AuthAuthenticated) {
///       return DashboardPage();
///     }
///     // ...
///   },
/// )
/// ```
///
/// ============================================================================

import 'package:equatable/equatable.dart';
import '../models/user_model.dart';

/// Classe base abstrata para todos os estados de autenticação.
///
/// Estende [Equatable] para comparação eficiente de estados,
/// evitando rebuilds desnecessários no BLoC.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial do fluxo de autenticação.
///
/// Este é o estado padrão quando o app inicia,
/// antes de verificar se há usuário logado.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carregamento durante operações assíncronas.
///
/// Usado durante:
/// - Login
/// - Logout
/// - Envio de email de redefinição
///
/// A UI deve exibir um indicador de loading neste estado.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado de usuário autenticado com sucesso.
///
/// Contém o [UserModel] do usuário logado.
/// A UI deve redirecionar para o Dashboard neste estado.
class AuthAuthenticated extends AuthState {
  /// Usuário autenticado
  final UserModel user;

  const AuthAuthenticated(this.user);

  /// Incluímos o user nas props para comparação
  @override
  List<Object?> get props => [user];
}

/// Estado após envio bem-sucedido de email de redefinição.
///
/// A UI deve mostrar mensagem de sucesso e instruções.
class AuthPasswordResetSent extends AuthState {
  /// Email para o qual o link foi enviado
  final String email;

  const AuthPasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}

/// Estado de erro durante operação de autenticação.
///
/// Contém a mensagem de erro para exibição ao usuário.
/// A UI deve mostrar o erro e permitir nova tentativa.
class AuthError extends AuthState {
  /// Mensagem de erro amigável para o usuário
  final String message;

  /// Código de erro (opcional, para debugging/analytics)
  final String? code;

  const AuthError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Estado de usuário não autenticado (logout realizado).
///
/// Similar ao [AuthInitial], mas indica que o logout
/// foi feito explicitamente.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
