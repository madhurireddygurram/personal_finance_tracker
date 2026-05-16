import 'package:hive_flutter/hive_flutter.dart';

class UserService {
  static const String _boxName = 'user';

  static Future<void> init() async {
    // Box is opened after Hive.initFlutter() in HiveService.init()
    // We just open the user box here — no platform-specific path needed
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static Box get _box => Hive.box(_boxName);

  // ── Auth ──────────────────────────────────────────────────

  static Future<void> saveUser({
    required String name,
    required String email,
    required String password,
  }) async {
    await _box.put('name', name.trim());
    await _box.put('email', email.trim().toLowerCase());
    await _box.put('password', password);
    await _box.flush();
  }

  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    await _box.put('name', name.trim());
    await _box.put('email', email.trim().toLowerCase());
    await _box.flush();
  }

  static String get name => _box.get('name', defaultValue: '') as String;
  static String get email => _box.get('email', defaultValue: '') as String;
  static String get password => _box.get('password', defaultValue: '') as String;
  static String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'U';

  // ── Setup ─────────────────────────────────────────────────

  static Future<void> saveSetup({
    required double income,
    required double budget,
    required String currency,
    String goal = '',
    bool isStudent = false,
  }) async {
    await _box.put('income', income);
    await _box.put('budget', budget);
    await _box.put('currency', currency);
    await _box.put('goal', goal);
    await _box.put('isStudent', isStudent);
    await _box.put('setupDone', true);
    await _box.flush();
  }

  static double get income =>
      (_box.get('income', defaultValue: 0.0) as num).toDouble();
  static double get budget =>
      (_box.get('budget', defaultValue: 0.0) as num).toDouble();
  static String get currency =>
      _box.get('currency', defaultValue: '₹') as String;
  static String get goal => _box.get('goal', defaultValue: '') as String;
  static bool get setupDone =>
      _box.get('setupDone', defaultValue: false) as bool;
  static bool get isStudent =>
      _box.get('isStudent', defaultValue: false) as bool;

  // ── Language ──────────────────────────────────────────────
  static String get language =>
      _box.get('language', defaultValue: 'English') as String;

  static Future<void> setLanguage(String lang) async {
    await _box.put('language', lang);
    await _box.flush();
  }

  // ── Session ───────────────────────────────────────────────

  static bool get isLoggedIn =>
      _box.get('loggedIn', defaultValue: false) as bool;

  static Future<void> setLoggedIn(bool v) async {
    await _box.put('loggedIn', v);
    await _box.flush();
  }

  static bool get onboardingDone =>
      _box.get('onboardingDone', defaultValue: false) as bool;

  static Future<void> setOnboardingDone() async {
    await _box.put('onboardingDone', true);
    await _box.flush();
  }

  static Future<void> logout() async {
    await _box.put('loggedIn', false);
    await _box.put('setupDone', false);
    await _box.flush();
  }

  // Called after login to re-mark setup as done (income was already saved)
  static Future<void> restoreSetupDone() async {
    if (income > 0) {
      await _box.put('setupDone', true);
      await _box.flush();
    }
  }

  // ── Savings pot (separate from balance) ───────────────────
  // This is a manually managed savings amount.
  // Depositing deducts from balance; withdrawing adds back.
  static double get savings =>
      (_box.get('savings', defaultValue: 0.0) as num).toDouble();

  static Future<void> updateSavings(double amount) async {
    await _box.put('savings', amount < 0 ? 0.0 : amount);
    await _box.flush();
  }
}
