import 'package:flutter/material.dart';

// ── Theme Notifier ────────────────────────────────────────────────────────────

class ThemeNotifier extends ChangeNotifier {
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;
  ThemeNotifier._internal();

  bool _isDark = true;
  bool get isDark => _isDark;

  void setDark(bool value) {
    _isDark = value;
    notifyListeners();
  }

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// ── Color Tokens ──────────────────────────────────────────────────────────────

class _DarkColors {
  static const bg          = Color(0xFF0A0A0B);
  static const surface     = Color(0xFF131315);
  static const surfaceHigh = Color(0xFF1C1C1F);
  static const surfaceTop  = Color(0xFF252528);
  static const border      = Color(0xFF242427);
  static const borderSoft  = Color(0xFF1E1E21);
  static const accent      = Color(0xFF00E87A);
  static const accentDim   = Color(0xFF00B35E);
  static const accentGlow  = Color(0xFF00E87A);
  static const textPrimary = Color(0xFFF0F0F2);
  static const textSec     = Color(0xFF78787F);
  static const textHint    = Color(0xFF3A3A3F);
  static const danger      = Color(0xFFFF3B55);
  static const bubbleSelf  = Color(0xFF0F2318);
  static const bubbleOther = Color(0xFF17171A);
  static const online      = Color(0xFF00E87A);
  static const offline     = Color(0xFF3A3A3F);
}

class _LightColors {
  static const bg          = Color(0xFFF5F5F7);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFF0F0F4);
  static const surfaceTop  = Color(0xFFE8E8EC);
  static const border      = Color(0xFFE0E0E6);
  static const borderSoft  = Color(0xFFEAEAF0);
  static const accent      = Color(0xFF00A855);
  static const accentDim   = Color(0xFF007A3D);
  static const accentGlow  = Color(0xFF00C965);
  static const textPrimary = Color(0xFF0A0A0B);
  static const textSec     = Color(0xFF6B6B72);
  static const textHint    = Color(0xFFB0B0B8);
  static const danger      = Color(0xFFE8203A);
  static const bubbleSelf  = Color(0xFFDCF5E8);
  static const bubbleOther = Color(0xFFFFFFFF);
  static const online      = Color(0xFF00A855);
  static const offline     = Color(0xFFB0B0B8);
}

// ── AppTheme ──────────────────────────────────────────────────────────────────

class AppTheme {
  // Static dark-mode accessors (backward-compat)
  static const Color bg          = _DarkColors.bg;
  static const Color surface     = _DarkColors.surface;
  static const Color surfaceHigh = _DarkColors.surfaceHigh;
  static const Color surfaceTop  = _DarkColors.surfaceTop;
  static const Color border      = _DarkColors.border;
  static const Color borderSoft  = _DarkColors.borderSoft;
  static const Color accent      = _DarkColors.accent;
  static const Color accentDim   = _DarkColors.accentDim;
  static const Color accentGlow  = _DarkColors.accentGlow;
  static const Color textPrimary = _DarkColors.textPrimary;
  static const Color textSec     = _DarkColors.textSec;
  static const Color textHint    = _DarkColors.textHint;
  static const Color danger      = _DarkColors.danger;
  static const Color bubbleSelf  = _DarkColors.bubbleSelf;
  static const Color bubbleOther = _DarkColors.bubbleOther;
  static const Color online      = _DarkColors.online;

  // ── Dynamic color resolver ──────────────────────────────────────────────
  static AppColors of(BuildContext context) {
    final isDark = ThemeNotifier().isDark;
    return isDark ? AppColors.dark() : AppColors.light();
  }

  // ── ThemeData builders ──────────────────────────────────────────────────
  static ThemeData get darkTheme  => _buildTheme(dark: true);
  static ThemeData get lightTheme => _buildTheme(dark: false);
  static ThemeData get theme      => darkTheme; // legacy

  static ThemeData _buildTheme({required bool dark}) {
    final _BaseTokens c = dark ? _dark : _light;

    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: c.bg,
      fontFamily: 'DMMono',
colorScheme: ColorScheme.fromSeed(
  seedColor: c.accent,
  brightness: dark ? Brightness.dark : Brightness.light,
).copyWith(
  surface: c.surface,
  onSurface: c.textPrimary,
),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'DMMono',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: c.textPrimary,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: c.textSec),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: c.textHint, fontFamily: 'DMMono'),
        labelStyle: TextStyle(color: c.textSec, fontFamily: 'DMMono'),
      ),
      dividerColor: c.border,
      dividerTheme: DividerThemeData(color: c.border, thickness: 0.5),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bg,
        selectedItemColor: c.accent,
        unselectedItemColor: c.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.textHint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.accent.withValues(alpha: 0.3)
              : c.surfaceTop,
        ),
      ),
    );
  }



  static final _dark  = _DarkTokens();
  static final _light = _LightTokens();
}

// ── Dynamic AppColors (use AppTheme.of(context)) ──────────────────────────────

class AppColors {
  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceTop;
  final Color border;
  final Color borderSoft;
  final Color accent;
  final Color accentDim;
  final Color accentGlow;
  final Color textPrimary;
  final Color textSec;
  final Color textHint;
  final Color danger;
  final Color bubbleSelf;
  final Color bubbleOther;
  final Color online;
  final Color offline;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceTop,
    required this.border,
    required this.borderSoft,
    required this.accent,
    required this.accentDim,
    required this.accentGlow,
    required this.textPrimary,
    required this.textSec,
    required this.textHint,
    required this.danger,
    required this.bubbleSelf,
    required this.bubbleOther,
    required this.online,
    required this.offline,
  });

  factory AppColors.dark() => const AppColors(
    bg: _DarkColors.bg, surface: _DarkColors.surface,
    surfaceHigh: _DarkColors.surfaceHigh, surfaceTop: _DarkColors.surfaceTop,
    border: _DarkColors.border, borderSoft: _DarkColors.borderSoft,
    accent: _DarkColors.accent, accentDim: _DarkColors.accentDim,
    accentGlow: _DarkColors.accentGlow, textPrimary: _DarkColors.textPrimary,
    textSec: _DarkColors.textSec, textHint: _DarkColors.textHint,
    danger: _DarkColors.danger, bubbleSelf: _DarkColors.bubbleSelf,
    bubbleOther: _DarkColors.bubbleOther, online: _DarkColors.online,
    offline: _DarkColors.offline,
  );

  factory AppColors.light() => const AppColors(
    bg: _LightColors.bg, surface: _LightColors.surface,
    surfaceHigh: _LightColors.surfaceHigh, surfaceTop: _LightColors.surfaceTop,
    border: _LightColors.border, borderSoft: _LightColors.borderSoft,
    accent: _LightColors.accent, accentDim: _LightColors.accentDim,
    accentGlow: _LightColors.accentGlow, textPrimary: _LightColors.textPrimary,
    textSec: _LightColors.textSec, textHint: _LightColors.textHint,
    danger: _LightColors.danger, bubbleSelf: _LightColors.bubbleSelf,
    bubbleOther: _LightColors.bubbleOther, online: _LightColors.online,
    offline: _LightColors.offline,
  );
}



abstract class _BaseTokens {
  Color get bg;
  Color get surface;
  Color get surfaceHigh;
  Color get surfaceTop;
  Color get border;
  Color get accent;
  Color get accentDim;
  Color get textPrimary;
  Color get textSec;
  Color get textHint;
  Color get danger;
}

// Internal token classes (for
// ThemeData building without BuildContext)
class _DarkTokens implements _BaseTokens {
  @override
  Color get bg          => _DarkColors.bg;
  @override
  Color get surface     => _DarkColors.surface;
  @override
  Color get surfaceHigh => _DarkColors.surfaceHigh;
  @override
  Color get surfaceTop  => _DarkColors.surfaceTop;
  @override
  Color get border      => _DarkColors.border;
  @override
  Color get accent      => _DarkColors.accent;
  @override
  Color get accentDim   => _DarkColors.accentDim;
  @override
  Color get textPrimary => _DarkColors.textPrimary;
  @override
  Color get textSec     => _DarkColors.textSec;
  @override
  Color get textHint    => _DarkColors.textHint;
  @override
  Color get danger      => _DarkColors.danger;
}

class _LightTokens implements _BaseTokens {
  @override
  Color get bg          => _LightColors.bg;
  @override
  Color get surface     => _LightColors.surface;
  @override
  Color get surfaceHigh => _LightColors.surfaceHigh;
  @override
  Color get surfaceTop  => _LightColors.surfaceTop;
  @override
  Color get border      => _LightColors.border;
  @override
  Color get accent      => _LightColors.accent;
  @override
  Color get accentDim   => _LightColors.accentDim;
  @override
  Color get textPrimary => _LightColors.textPrimary;
  @override
  Color get textSec     => _LightColors.textSec;
  @override
  Color get textHint    => _LightColors.textHint;
  @override
  Color get danger      => _LightColors.danger;
}

// ── Avatar helpers ────────────────────────────────────────────────────────────

const List<Color> kAvatarColors = [
  Color(0xFF00E87A),
  Color(0xFF4A9EFF),
  Color(0xFFFF6B6B),
  Color(0xFFFFB347),
  Color(0xFFDA70D6),
  Color(0xFF40E0D0),
  Color(0xFFFF69B4),
  Color(0xFF98FB98),
];

Color avatarColor(String username) =>
    kAvatarColors[username.codeUnits.fold(0, (a, b) => a + b) % kAvatarColors.length];

String avatarInitials(String username) =>
    username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : '?';