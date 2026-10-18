import 'package:flutter/material.dart';

/// Material 3 themes. A school's brand color (if any) is used as an accent
/// for school-specific surfaces via [schoolColorScheme], while the app chrome
/// keeps the neutral product palette.
abstract final class AppTheme {
  static const seed = Color(0xFF1D4ED8);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  /// A color scheme derived from a school's brand color, matching the
  /// brightness of [context]. Falls back to the current scheme.
  static ColorScheme schoolColorScheme(BuildContext context, String? hex) {
    final current = Theme.of(context).colorScheme;
    final color = parseHexColor(hex);
    if (color == null) return current;
    return ColorScheme.fromSeed(
      seedColor: color,
      brightness: current.brightness,
    );
  }
}

/// Parses `#RRGGBB` (the database `hex_color` domain). Returns `null` for
/// anything else.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex.trim());
  if (match == null) return null;
  return Color(int.parse('FF${match.group(1)}', radix: 16));
}
