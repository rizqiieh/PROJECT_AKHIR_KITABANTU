import 'package:flutter/material.dart';

/// Palet warna resmi KitaBantu (Bab 7 — Arahan Visual & Desain UI).
///
/// Referensi:
/// - Hijau Utama  (Primary)      : #4F8268
/// - Hijau Sage   (Secondary)    : #98B18A
/// - Latar Hangat (Background)   : #F7F7F1
/// - Permukaan    (Surface)      : #FFFFFF
/// - Teks Utama   (On Surface)   : #24352C
/// - Sukses / Valid              : #2E7D32
/// - Peringatan / Simulasi       : #EF6C00
/// - Error                       : #C62828
class AppColors {
  AppColors._(); // Mencegah instansiasi

  // ──────────────── Warna Utama ────────────────
  static const Color primary       = Color(0xFF4F8268);
  static const Color primaryLight  = Color(0xFF7BA895);
  static const Color primaryDark   = Color(0xFF2E5C3F);

  static const Color secondary     = Color(0xFF98B18A);
  static const Color secondaryLight = Color(0xFFBDD1B3);
  static const Color secondaryDark = Color(0xFF6E8A60);

  // ──────────────── Permukaan & Latar ────────────────
  static const Color background    = Color(0xFFF7F7F1);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0EA);

  // ──────────────── Teks ────────────────
  static const Color onPrimary     = Color(0xFFFFFFFF);
  static const Color onSecondary   = Color(0xFF24352C);
  static const Color onBackground  = Color(0xFF24352C);
  static const Color onSurface     = Color(0xFF24352C);
  static const Color onSurfaceVariant = Color(0xFF5A6B5F);
  static const Color textHint      = Color(0xFF9E9E9E);

  // ──────────────── Status ────────────────
  static const Color success       = Color(0xFF2E7D32);
  static const Color warning       = Color(0xFFEF6C00);
  static const Color error         = Color(0xFFC62828);

  // ──────────────── Lain-lain ────────────────
  static const Color divider       = Color(0xFFE0E0E0);
  static const Color shimmerBase   = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
