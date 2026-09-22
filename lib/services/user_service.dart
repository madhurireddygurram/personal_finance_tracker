import 'package:hive_flutter/hive_flutter.dart';

enum AuthResult { success, wrongPassword, userNotFound }

class UserService {
  static const String _boxName = 'user';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static Box get _box => Hive.box(_boxName);

  static Map<String, dynamic> _getAllUsers() {
    final raw = _box.get('users');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  // ── Auth & Accounts ───────────────────────────────────────

  static bool get hasAnyAccount {
    final users = _getAllUsers();
    return users.isNotEmpty || email.isNotEmpty;
  }

  static bool accountExists(String checkEmail) {
    final clean = checkEmail.trim().toLowerCase();
    final users = _getAllUsers();
    if (users.containsKey(clean)) return true;
    return email.toLowerCase() == clean && email.isNotEmpty;
  }

  static String? findPassword(String checkEmail) {
    final clean = checkEmail.trim().toLowerCase();
    final users = _getAllUsers();
    if (users.containsKey(clean)) {
      final u = Map<String, dynamic>.from(users[clean] as Map);
      return u['password'] as String?;
    }
    if (email.toLowerCase() == clean && password.isNotEmpty) {
      return password;
    }
    return null;
  }

  static Future<void> saveUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final users = _getAllUsers();

    final existing = users[cleanEmail] != null
        ? Map<String, dynamic>.from(users[cleanEmail] as Map)
        : <String, dynamic>{};

    final userData = {
      'name': cleanName,
      'email': cleanEmail,
      'password': password,
      'income': existing['income'] ?? 25000.0,
      'budget': existing['budget'] ?? 15000.0,
      'currency': existing['currency'] ?? '₹',
      'goal': existing['goal'] ?? '',
      'isStudent': existing['isStudent'] ?? false,
    };

    users[cleanEmail] = userData;
    await _box.put('users', users);
    await _box.put('currentUser', cleanEmail);

    // Also update active session keys
    await _box.put('name', cleanName);
    await _box.put('email', cleanEmail);
    await _box.put('password', password);
    await _box.put('income', userData['income']);
    await _box.put('budget', userData['budget']);
    await _box.put('currency', userData['currency']);
    await _box.put('goal', userData['goal']);
    await _box.put('isStudent', userData['isStudent']);
    await _box.put('setupDone', true);
    await _box.put('loggedIn', true);
    await _box.flush();
  }

  static Future<AuthResult> authenticate(String emailInput, String passwordInput) async {
    final clean = emailInput.trim().toLowerCase();
    final users = _getAllUsers();

    if (users.containsKey(clean)) {
      final u = Map<String, dynamic>.from(users[clean] as Map);
      if (u['password'] == passwordInput) {
        // Switch active user session
        await _box.put('currentUser', clean);
        await _box.put('name', u['name'] ?? '');
        await _box.put('email', clean);
        await _box.put('password', passwordInput);
        if (u['income'] != null) await _box.put('income', u['income']);
        if (u['budget'] != null) await _box.put('budget', u['budget']);
        if (u['currency'] != null) await _box.put('currency', u['currency']);
        if (u['goal'] != null) await _box.put('goal', u['goal']);
        if (u['isStudent'] != null) await _box.put('isStudent', u['isStudent']);
        await _box.put('setupDone', true);
        await _box.put('loggedIn', true);
        await _box.flush();
        return AuthResult.success;
      } else {
        return AuthResult.wrongPassword;
      }
    }

    // Fallback for legacy single-account data
    final legacyEmail = (_box.get('email', defaultValue: '') as String).trim().toLowerCase();
    final legacyPass = _box.get('password', defaultValue: '') as String;
    if (legacyEmail.isNotEmpty && legacyEmail == clean) {
      if (legacyPass == passwordInput) {
        await _box.put('loggedIn', true);
        await _box.put('setupDone', true);
        await _box.flush();
        return AuthResult.success;
      } else {
        return AuthResult.wrongPassword;
      }
    }

    return AuthResult.userNotFound;
  }

  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    final users = _getAllUsers();
    final currentKey = (_box.get('currentUser', defaultValue: '') as String).toLowerCase();
    final keyToUpdate = currentKey.isNotEmpty ? currentKey : UserService.email.toLowerCase();

    if (users.containsKey(keyToUpdate)) {
      final u = Map<String, dynamic>.from(users[keyToUpdate] as Map);
      u['name'] = cleanName;
      u['email'] = cleanEmail;
      users.remove(keyToUpdate);
      users[cleanEmail] = u;
      await _box.put('users', users);
      await _box.put('currentUser', cleanEmail);
    }

    await _box.put('name', cleanName);
    await _box.put('email', cleanEmail);
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
    final cleanEmail = email.trim().toLowerCase();
    final users = _getAllUsers();
    if (users.containsKey(cleanEmail)) {
      final u = Map<String, dynamic>.from(users[cleanEmail] as Map);
      u['income'] = income;
      u['budget'] = budget;
      u['currency'] = currency;
      u['goal'] = goal;
      u['isStudent'] = isStudent;
      users[cleanEmail] = u;
      await _box.put('users', users);
    }

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
    // Keep user credentials and setup data intact! Only revoke active session.
    await _box.put('loggedIn', false);
    await _box.flush();
  }

  static Future<void> restoreSetupDone() async {
    await _box.put('setupDone', true);
    await _box.flush();
  }

  // ── Savings pot (separate from balance) ───────────────────
  static double get savings =>
      (_box.get('savings', defaultValue: 0.0) as num).toDouble();

  static Future<void> updateSavings(double amount) async {
    await _box.put('savings', amount < 0 ? 0.0 : amount);
    await _box.flush();
  }
}

