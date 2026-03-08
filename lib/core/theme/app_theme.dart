library atlas_theme;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores privadas do aplicativo com foco em Alto Contraste e Vibração.
class _AppColors {
  // Cor primária: Um azul vibrante e moderno
  static const Color primarySeed = Color(0xFF007AFF);

  // Acentos
  static const Color accentNeon = Color(0xFF00E5FF); // Cyano vibrante
  static const Color accentCoral = Color(
    0xFFFF5252,
  ); // Coral para alertas/destaques

  // Cores de Feedback
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF3D00);
}

/// Classe principal de tema do aplicativo.
class AppTheme {
  // Construtor privado para evitar instanciação
  AppTheme._();

  /// Tema claro do aplicativo.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _AppColors.primarySeed,
      brightness: Brightness.light,
      primary: _AppColors.primarySeed,
      secondary: _AppColors.accentNeon,
      tertiary: _AppColors.accentCoral,
      surface: const Color(0xFFF8F9FA),
      surfaceContainerLow: const Color(0xFFFFFFFF),
    );

    // Usa a fonte Outfit para todo o app, mantendo o esquema de cores base do tema
    final baseTextTheme = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: baseTextTheme,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, // AppBar transparente por padrão
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: colorScheme.primary.withValues(alpha: 0.4),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0, // Tiramos a sombra dura para usar bordas suaves
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Tema escuro do aplicativo.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _AppColors.primarySeed,
      brightness: Brightness.dark,
      // Fundo mais escuro para OLED/Darker Mode real
      surface: const Color(0xFF0F0F13),
      surfaceContainerLow: const Color(0xFF1A1A24),
      primary: const Color(0xFF409CFF), // Azul mais claro pro dark mode
      secondary: _AppColors.accentNeon,
    );

    final baseTextTheme = GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor: const Color(0xFF0F0F13),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 6,
          shadowColor: colorScheme.primary.withValues(alpha: 0.5),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Cor de sucesso para check-ins realizados
  static Color get successColor => _AppColors.success;

  /// Cor de erro para estados de falha
  static Color get errorColor => _AppColors.error;
}
