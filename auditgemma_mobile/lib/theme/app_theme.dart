import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Color Tokens ───────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFF0A0E17);
  static const Color bgSurface = Color(0xFF111827);
  static const Color bgElevated = Color(0xFF1E293B);
  static const Color bgHover = Color(0xFF263348);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const Color accent = Color(0xFF6366F1);
  static const Color accentHover = Color(0xFF818CF8);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color border = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFF334155);

  // ─── Score Gradient ─────────────────────────────────────────────
  /// Maps a score (0-100) to a Color using continuous piecewise HSL:
  ///   0   → deep red    HSL(0, 80%, 45%)
  ///   50  → amber       HSL(45, 90%, 50%)
  ///   100 → green       HSL(145, 70%, 42%)
  static Color scoreToColor(int score) {
    final s = score.clamp(0, 100);
    double h, sat, light;

    if (s <= 50) {
      final t = s / 50.0;
      h = _lerp(0, 45, t);
      sat = _lerp(0.80, 0.90, t);
      light = _lerp(0.45, 0.50, t);
    } else {
      final t = (s - 50) / 50.0;
      h = _lerp(45, 145, t);
      sat = _lerp(0.90, 0.70, t);
      light = _lerp(0.50, 0.42, t);
    }

    return HSLColor.fromAHSL(1.0, h, sat, light).toColor();
  }

  /// Muted/darker variant of score color for backgrounds
  static Color scoreToMutedColor(int score) {
    final s = score.clamp(0, 100);
    double h, sat, light;

    if (s <= 50) {
      final t = s / 50.0;
      h = _lerp(0, 45, t);
      sat = _lerp(0.50, 0.55, t);
      light = _lerp(0.18, 0.20, t);
    } else {
      final t = (s - 50) / 50.0;
      h = _lerp(45, 145, t);
      sat = _lerp(0.55, 0.45, t);
      light = _lerp(0.20, 0.18, t);
    }

    return HSLColor.fromAHSL(1.0, h, sat, light).toColor();
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ─── Status Colors ──────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return warning;
      case 'approved':
        return success;
      case 'escalated':
        return danger;
      case 'requires_documents':
        return info;
      default:
        return textMuted;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'escalated':
        return 'Escalated';
      case 'requires_documents':
        return 'Docs Required';
      default:
        return status;
    }
  }

  // ─── ThemeData ──────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accentHover,
        surface: bgSurface,
        onSurface: textPrimary,
        error: danger,
        onError: Colors.white,
      ),
      cardColor: bgSurface,
      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgSurface,
        modalBackgroundColor: bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textSecondary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: textMuted,
          fontSize: 12,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
