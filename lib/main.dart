/// ============================================================================
/// MAIN.DART - Ponto de Entrada do Aplicativo
/// ============================================================================
///
/// Arquivo de entrada do aplicativo Atlas.
///
/// RESPONSABILIDADES:
/// - Inicializar bindings do Flutter
/// - Inicializar serviços externos (Firebase)
/// - Iniciar o aplicativo
///
/// PREPARAÇÃO PARA FIREBASE:
///
/// 1. Descomente as linhas marcadas com [FIREBASE_REAL]
/// 2. Configure o firebase_options.dart via FlutterFire CLI:
///    flutterfire configure
/// 3. Importe o arquivo gerado
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/firebase_service.dart';

/// Função principal do aplicativo.
///
/// Configuração assíncrona:
/// 1. Garante que os bindings do Flutter estão inicializados
/// 2. Inicializa o Firebase
/// 3. Executa o app
void main() async {
  // Garante que os bindings do Flutter estão inicializados
  // Necessário para chamadas assíncronas antes de runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções geradas pelo FlutterFire CLI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa o serviço wrapper do Firebase
  await FirebaseService.instance.initialize();

  // Inicia o aplicativo
  runApp(const App());
}
