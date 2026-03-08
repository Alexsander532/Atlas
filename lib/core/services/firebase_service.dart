/// ============================================================================
/// FIREBASE SERVICE - Serviço de Inicialização do Firebase
/// ============================================================================
///
/// Este arquivo contém a configuração central do Firebase.
/// Atualmente usa implementação mock para desenvolvimento.
///
/// PREPARAÇÃO PARA FIREBASE REAL:
///
/// 1. Adicione as dependências no pubspec.yaml:
///    firebase_core: ^latest
///    firebase_auth: ^latest
///    cloud_firestore: ^latest
///
/// 2. Configure o Firebase no console:
///    https://console.firebase.google.com
///
/// 3. Adicione os arquivos de configuração:
///    - Android: google-services.json em android/app/
///    - iOS: GoogleService-Info.plist em ios/Runner/
///    - Web: Configure no index.html
///
/// 4. Descomente o código marcado com [FIREBASE_REAL]
///
/// ============================================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

/// Serviço singleton para gerenciar a conexão com Firebase.
///
/// Padrão Singleton: Garante uma única instância do serviço
/// em toda a aplicação, evitando múltiplas inicializações.
class FirebaseService {
  // Instância singleton privada
  static FirebaseService? _instance;

  // Flag indicando se o Firebase foi inicializado
  bool _isInitialized = false;

  // Construtor privado para evitar instanciação externa
  FirebaseService._();

  /// Retorna a instância única do FirebaseService.
  ///
  /// Uso:
  /// ```dart
  /// final firebase = FirebaseService.instance;
  /// await firebase.initialize();
  /// ```
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  /// Indica se o Firebase está inicializado
  bool get isInitialized => _isInitialized;

  // ============================================================
  // INICIALIZAÇÃO
  // ============================================================

  /// Inicializa o Firebase.
  ///
  /// Deve ser chamado no main() antes de runApp().
  ///
  /// Retorna [true] se inicializado com sucesso.
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Garante que o Firebase está inicializado (chamada dupla é segura com DefaultFirebaseOptions)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _isInitialized = true;
      print('✅ FirebaseService: Inicializado com sucesso');
      return true;
    } catch (e) {
      print('❌ FirebaseService: Erro ao inicializar - $e');
      return false;
    }
  }

  // ============================================================
  // AUTENTICAÇÃO
  // ============================================================

  FirebaseAuth get auth => FirebaseAuth.instance;

  /// Stream de mudanças no estado de autenticação
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Usuário atual (null se não autenticado)
  User? get currentUser => auth.currentUser;

  // ============================================================
  // FIRESTORE
  // ============================================================

  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Referência para coleção de usuários
  CollectionReference get usersCollection => firestore.collection('users');

  /// Referência para coleção de check-ins
  CollectionReference get checkinsCollection =>
      firestore.collection('checkins');

  /// Gera ID de documento para check-in: {userId}_{date}
  /// Isso garante apenas 1 check-in por usuário por dia
  String generateCheckinDocId(String userId, String date) {
    return '${userId}_$date';
  }
}
