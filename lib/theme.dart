import 'package:flutter/material.dart';
import 'store.dart';

/// Renk paleti. Bütün ekranlar renkleri buradan alır, böylece tema değişince her şey değişir.
class Palette {
  final String id;
  final String name;
  final bool dark;
  final Color bg;
  final Color surface;
  final Color card;
  final Color line;
  final Color text;
  final Color dim;
  final Color accent;
  final Color onAccent;
  const Palette({
    required this.id,
    required this.name,
    required this.dark,
    required this.bg,
    required this.surface,
    required this.card,
    required this.line,
    required this.text,
    required this.dim,
    required this.accent,
    required this.onAccent,
  });
}

const kPalettes = [
  Palette(
    id: 'volt',
    name: 'Volt',
    dark: true,
    bg: Color(0xFF0B0C0F),
    surface: Color(0xFF14161B),
    card: Color(0xFF1B1E25),
    line: Color(0xFF2A2E37),
    text: Color(0xFFF4F6FA),
    dim: Color(0xFF8B92A1),
    accent: Color(0xFFC6FF00),
    onAccent: Color(0xFF0B0C0F),
  ),
  Palette(
    id: 'ates',
    name: 'Ateş',
    dark: true,
    bg: Color(0xFF0E0B0A),
    surface: Color(0xFF181312),
    card: Color(0xFF221A18),
    line: Color(0xFF352825),
    text: Color(0xFFFFF5F0),
    dim: Color(0xFFA2918B),
    accent: Color(0xFFFF6A2B),
    onAccent: Color(0xFF140B07),
  ),
  Palette(
    id: 'okyanus',
    name: 'Okyanus',
    dark: true,
    bg: Color(0xFF070C14),
    surface: Color(0xFF0E1622),
    card: Color(0xFF14202F),
    line: Color(0xFF223246),
    text: Color(0xFFF0F7FF),
    dim: Color(0xFF8397AE),
    accent: Color(0xFF22D3EE),
    onAccent: Color(0xFF04121A),
  ),
  Palette(
    id: 'neon',
    name: 'Neon Mor',
    dark: true,
    bg: Color(0xFF0C0A12),
    surface: Color(0xFF15121E),
    card: Color(0xFF1E1A2B),
    line: Color(0xFF2F2942),
    text: Color(0xFFF7F4FF),
    dim: Color(0xFF9A92B0),
    accent: Color(0xFFB07CFF),
    onAccent: Color(0xFF120A20),
  ),
  Palette(
    id: 'altin',
    name: 'Altın',
    dark: true,
    bg: Color(0xFF0D0C09),
    surface: Color(0xFF17150F),
    card: Color(0xFF211E16),
    line: Color(0xFF332E22),
    text: Color(0xFFFFFAEE),
    dim: Color(0xFFA39A85),
    accent: Color(0xFFFFC53D),
    onAccent: Color(0xFF181203),
  ),
  Palette(
    id: 'gunduz',
    name: 'Gündüz (açık)',
    dark: false,
    bg: Color(0xFFF3F4F7),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE1E4EA),
    text: Color(0xFF12141A),
    dim: Color(0xFF6B7280),
    accent: Color(0xFF3B5BFF),
    onAccent: Color(0xFFFFFFFF),
  ),
];

Palette get pal => kPalettes.firstWhere((p) => p.id == store.themeId, orElse: () => kPalettes.first);

const kYellow = Color(0xFFFFC928);
const kRed = Color(0xFFFF3B30);
const kGreen = Color(0xFF34D399);

ThemeData buildTheme(Palette p) {
  final base = p.dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: p.dark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: p.accent,
    onPrimary: p.onAccent,
    surface: p.surface,
    onSurface: p.text,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    textTheme: base.textTheme.apply(fontFamily: 'Poppins', bodyColor: p.text, displayColor: p.text),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Poppins'),
    dividerColor: p.line,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: p.text),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.card,
      contentTextStyle: TextStyle(fontFamily: 'Poppins', color: p.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      labelStyle: TextStyle(color: p.dim),
      hintStyle: TextStyle(color: p.dim.withValues(alpha: 0.7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.accent, width: 2)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: p.card,
      selectedColor: p.accent,
      side: BorderSide(color: p.line),
      labelStyle: TextStyle(fontFamily: 'Poppins', color: p.text),
      secondaryLabelStyle: TextStyle(fontFamily: 'Poppins', color: p.onAccent),
      checkmarkColor: p.onAccent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? p.accent : p.dim)),
      iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.accent : p.dim)),
    ),
  );
}

const kRegionColors = [
  Color(0xFFC6FF00), Color(0xFF22D3EE), Color(0xFFFF6A2B), Color(0xFFB07CFF),
  Color(0xFFFFC53D), Color(0xFF34D399), Color(0xFFFF4D8D), Color(0xFF60A5FA),
];

/// Her bölgenin takvimde kendine ait rengi olur.
Color regionColor(String regionId, {bool rest = false}) {
  if (rest) return const Color(0xFF8B92A1);
  final i = store.regions.indexWhere((r) => r.id == regionId);
  final idx = i >= 0 ? i : regionId.codeUnits.fold<int>(0, (a, b) => a + b);
  return kRegionColors[idx % kRegionColors.length];
}
