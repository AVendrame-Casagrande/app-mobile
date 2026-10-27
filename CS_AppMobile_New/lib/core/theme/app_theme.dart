import 'package:flutter/material.dart';

/// Tema Casagrande — colori estratti dai CSS originali (css/index.css).
class AppColors {
  AppColors._();

  /// Colore hex Casagrande principale (#0d8a9e).
  static const Color casagrande = Color(0xFF0D8A9E);

  /// Sfondo intestazioni / barre (rgba(8,89,102,1)).
  static const Color casagrandeDark = Color(0xFF085966);

  /// Pulsante principale (rgba(0,150,160,1)).
  static const Color button = Color(0xFF0096A0);
  static const Color buttonRed = Color(0xCCFF3232); // rgba(255,50,50,0.8)
  static const Color buttonBlue = Color(0xE60064C8); // rgba(0,100,200,0.9)
  static const Color buttonOrange = Color(0xE6FF6400); // rgba(255,100,0,0.9)
  static const Color buttonGrey = Color(0x80000000); // rgba(0,0,0,0.5)

  /// Colore degli spinner di caricamento (rgba(89,102,168)).
  static const Color spinner = Color(0xFF5966A8);

  /// Sfondo generale dell'app (rgb(220,220,220)).
  static const Color background = Color(0xFFDCDCDC);

  static const Color toggleOn = Color(0xFF0A7080); // rgba(10,112,128,1)
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.casagrande,
        primary: AppColors.casagrande,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.casagrandeDark,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.button,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.spinner,
      ),
    );
  }
}
