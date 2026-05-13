import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppTheme {
  final String id;
  final String name;
  final String desc;
  final String unlockRequirement;
  final int badgesRequired;
  final Color primary;
  final Color secondary;
  final Color scaffold;
  final Color scaffoldDark;
  final Color card;
  final Color cardDark;
  final IconData icon;
  final List<Color> gradientColors;

  const AppTheme({
    required this.id,
    required this.name,
    required this.desc,
    required this.unlockRequirement,
    required this.badgesRequired,
    required this.primary,
    required this.secondary,
    required this.scaffold,
    required this.scaffoldDark,
    required this.card,
    required this.cardDark,
    required this.icon,
    required this.gradientColors,
  });
}

class ThemeService {
  static const _boxName = 'user';
  static const _key     = 'activeTheme';

  static Box get _box => Hive.box(_boxName);

  // ── All available themes ──────────────────────────────────
  static const List<AppTheme> themes = [
    AppTheme(
      id: 'emerald',
      name: 'Emerald',
      desc: 'The default fresh green theme',
      unlockRequirement: 'Available by default',
      badgesRequired: 0,
      primary: Color(0xFF00C853),
      secondary: Color(0xFF00897B),
      scaffold: Color(0xFFF5F7FA),
      scaffoldDark: Color(0xFF121212),
      card: Colors.white,
      cardDark: Color(0xFF1E1E1E),
      icon: Icons.eco_rounded,
      gradientColors: [Color(0xFF00C853), Color(0xFF00897B)],
    ),
    AppTheme(
      id: 'ocean',
      name: 'Ocean Blue',
      desc: 'Deep blue tones inspired by the sea',
      unlockRequirement: 'Unlock 1 badge',
      badgesRequired: 1,
      primary: Color(0xFF1565C0),
      secondary: Color(0xFF0288D1),
      scaffold: Color(0xFFF0F4FF),
      scaffoldDark: Color(0xFF0A0E1A),
      card: Colors.white,
      cardDark: Color(0xFF141B2D),
      icon: Icons.water_rounded,
      gradientColors: [Color(0xFF1565C0), Color(0xFF0288D1)],
    ),
    AppTheme(
      id: 'sunset',
      name: 'Sunset',
      desc: 'Warm orange and red tones',
      unlockRequirement: 'Unlock 3 badges',
      badgesRequired: 3,
      primary: Color(0xFFE64A19),
      secondary: Color(0xFFFF6D00),
      scaffold: Color(0xFFFFF8F5),
      scaffoldDark: Color(0xFF1A0A00),
      card: Colors.white,
      cardDark: Color(0xFF2D1200),
      icon: Icons.wb_sunny_rounded,
      gradientColors: [Color(0xFFE64A19), Color(0xFFFF6D00)],
    ),
    AppTheme(
      id: 'royal',
      name: 'Royal Purple',
      desc: 'Rich purple tones for royalty',
      unlockRequirement: 'Unlock 5 badges',
      badgesRequired: 5,
      primary: Color(0xFF6A1B9A),
      secondary: Color(0xFF7C4DFF),
      scaffold: Color(0xFFF8F5FF),
      scaffoldDark: Color(0xFF0D0014),
      card: Colors.white,
      cardDark: Color(0xFF1A0030),
      icon: Icons.auto_awesome_rounded,
      gradientColors: [Color(0xFF6A1B9A), Color(0xFF7C4DFF)],
    ),
    AppTheme(
      id: 'midnight',
      name: 'Midnight',
      desc: 'Sleek dark charcoal with gold accents',
      unlockRequirement: 'Unlock 7 badges',
      badgesRequired: 7,
      primary: Color(0xFFFFD700),
      secondary: Color(0xFFFFA000),
      scaffold: Color(0xFFF5F5F0),
      scaffoldDark: Color(0xFF0D0D0D),
      card: Colors.white,
      cardDark: Color(0xFF1A1A1A),
      icon: Icons.nights_stay_rounded,
      gradientColors: [Color(0xFF212121), Color(0xFFFFD700)],
    ),
    AppTheme(
      id: 'rose',
      name: 'Rose Gold',
      desc: 'Elegant pink and gold — unlock all badges',
      unlockRequirement: 'Unlock all 10 badges',
      badgesRequired: 10,
      primary: Color(0xFFAD1457),
      secondary: Color(0xFFFF4081),
      scaffold: Color(0xFFFFF5F8),
      scaffoldDark: Color(0xFF1A0010),
      card: Colors.white,
      cardDark: Color(0xFF2D0020),
      icon: Icons.workspace_premium_rounded,
      gradientColors: [Color(0xFFAD1457), Color(0xFFFF4081)],
    ),
  ];

  static AppTheme get active {
    final id = _box.get(_key, defaultValue: 'emerald') as String;
    return themes.firstWhere((t) => t.id == id,
        orElse: () => themes.first);
  }

  static Future<void> setTheme(String id) async {
    await _box.put(_key, id);
    await _box.flush();
  }

  static bool isUnlocked(AppTheme theme, int unlockedBadges) =>
      unlockedBadges >= theme.badgesRequired;

  // Build ThemeData from an AppTheme
  static ThemeData buildTheme(AppTheme t, Brightness brightness) {
    final isDark  = brightness == Brightness.dark;
    final primary = t.primary;
    final scheme  = ColorScheme.fromSeed(
      seedColor : primary,
      primary   : primary,
      secondary : t.secondary,
      brightness: brightness,
      surface   : isDark ? t.cardDark   : t.card,
      onPrimary : Colors.white,
    );
    return ThemeData(
      colorScheme            : scheme,
      scaffoldBackgroundColor: isDark ? t.scaffoldDark : t.scaffold,
      useMaterial3           : true,
      fontFamily             : 'Roboto',
      // Buttons always use primary
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize    : const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      // Switches use primary
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary
                : Colors.grey.shade300),
      ),
      // Progress indicators use primary
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled     : true,
        fillColor  : isDark ? t.cardDark : Colors.white,
        border     : OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide  : BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color    : isDark ? t.cardDark : t.card,
        shape    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
