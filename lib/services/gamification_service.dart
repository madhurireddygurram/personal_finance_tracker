import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import 'user_service.dart';

class GamificationService {
  static const _boxName = 'gamification';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static Box get _box => Hive.box(_boxName);

  // ── Streak ────────────────────────────────────────────────
  // A streak day = any day the user logged at least one expense.
  // Call this every time an expense is added.
  static Future<void> recordActivity() async {
    final today = _dayKey(DateTime.now());
    final lastDay = _box.get('lastDay', defaultValue: '') as String;
    final streak  = (_box.get('streak', defaultValue: 0) as num).toInt();

    if (lastDay == today) return; // already recorded today

    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final newStreak = lastDay == yesterday ? streak + 1 : 1;

    await _box.put('lastDay', today);
    await _box.put('streak', newStreak);
    if (newStreak > (_box.get('bestStreak', defaultValue: 0) as num).toInt()) {
      await _box.put('bestStreak', newStreak);
    }
    await _box.flush();
  }

  static int get streak =>
      (_box.get('streak', defaultValue: 0) as num).toInt();
  static int get bestStreak =>
      (_box.get('bestStreak', defaultValue: 0) as num).toInt();

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Savings Score (0–100) ─────────────────────────────────
  // Computed from: savings rate, budget adherence, streak, goals
  static int savingsScore(List<Expense> expenses) {
    int score = 0;
    final income  = UserService.income.toDouble();
    final budget  = UserService.budget.toDouble();
    final savings = UserService.savings;

    // No score until user has set up income AND logged at least one real expense
    final realExpenses = expenses.where((e) =>
        e.isExpense &&
        e.category != 'Savings' &&
        e.category != 'Goals').toList();

    if (income <= 0 || realExpenses.isEmpty) return 0;

    // 1. Savings rate (max 40 pts) — savings must be > 0
    if (savings > 0) {
      final savingsRate = (savings / income).clamp(0.0, 0.2);
      score += (savingsRate / 0.2 * 40).toInt();
    }

    // 2. Budget adherence (max 30 pts) — budget must be set
    if (budget > 0) {
      final totalExp = realExpenses.fold(0.0, (s, e) => s + e.amount);
      final ratio = (totalExp / budget).clamp(0.0, 2.0);
      if (ratio <= 1.0) score += (30 * (1 - ratio * 0.5)).toInt();
    }

    // 3. Streak bonus (max 20 pts) — streak must be > 0
    if (streak > 0) {
      score += (streak.clamp(0, 30) / 30 * 20).toInt();
    }

    // 4. Has savings (10 pts) — savings must be > 0
    if (savings > 0) score += 10;

    return score.clamp(0, 100);
  }

  static String scoreLabel(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Average';
    if (score >= 30) return 'Needs Work';
    return 'Getting Started';
  }

  // ── Badges ────────────────────────────────────────────────
  static List<AchievementBadge> badges(List<Expense> expenses) {
    final income  = UserService.income;
    final savings = UserService.savings;
    final budget  = UserService.budget;

    // Only count real spending expenses (not savings/goals/income)
    final realExpenses = expenses.where((e) =>
        e.isExpense &&
        e.category != 'Savings' &&
        e.category != 'Goals').toList();

    final totalExp = realExpenses.fold(0.0, (s, e) => s + e.amount);

    // Only count real spending categories (not system categories)
    final spendingCategories = realExpenses
        .map((e) => e.category)
        .where((c) => c != 'Income' && c != 'Savings' && c != 'Goals')
        .toSet();

    return [
      AchievementBadge(
        id: 'first_expense',
        title: 'First Step',
        desc: 'Log your first expense',
        icon: 'wallet',
        color: 0xFF00C853,
        // Must have at least 1 real expense
        unlocked: realExpenses.isNotEmpty,
      ),
      AchievementBadge(
        id: 'saver',
        title: 'Saver',
        desc: 'Save at least 10% of income',
        icon: 'savings',
        color: 0xFF00897B,
        // Must have income AND savings > 0 AND savings >= 10% of income
        unlocked: income > 0 && savings > 0 && savings >= income * 0.1,
      ),
      AchievementBadge(
        id: 'super_saver',
        title: 'Super Saver',
        desc: 'Save at least 20% of income',
        icon: 'star',
        color: 0xFFFFD700,
        unlocked: income > 0 && savings > 0 && savings >= income * 0.2,
      ),
      AchievementBadge(
        id: 'budget_master',
        title: 'Budget Master',
        desc: 'Stay within budget this month',
        icon: 'shield',
        color: 0xFF3D5AFE,
        // Must have budget set AND at least 1 real expense AND within budget
        unlocked: budget > 0 && realExpenses.isNotEmpty && totalExp <= budget,
      ),
      AchievementBadge(
        id: 'streak_3',
        title: 'On a Roll',
        desc: 'Track expenses 3 days in a row',
        icon: 'fire',
        color: 0xFFFF6D00,
        unlocked: streak >= 3,
      ),
      AchievementBadge(
        id: 'streak_7',
        title: 'Week Warrior',
        desc: 'Track expenses 7 days in a row',
        icon: 'fire',
        color: 0xFFFF5252,
        unlocked: streak >= 7,
      ),
      AchievementBadge(
        id: 'streak_30',
        title: 'Habit Builder',
        desc: '30-day tracking streak',
        icon: 'trophy',
        color: 0xFF7C4DFF,
        unlocked: streak >= 30,
      ),
      AchievementBadge(
        id: 'no_overspend',
        title: 'No Overspend',
        desc: 'Stay under 90% of budget for a full month',
        icon: 'check',
        color: 0xFF00BCD4,
        // Must have budget AND real expenses AND under 90% of budget
        unlocked: budget > 0 && realExpenses.isNotEmpty && totalExp < budget * 0.9,
      ),
      AchievementBadge(
        id: 'diversified',
        title: 'Diversified',
        desc: 'Track expenses in 5+ spending categories',
        icon: 'chart',
        color: 0xFFFF4081,
        // Only count real spending categories, not system ones
        unlocked: spendingCategories.length >= 5,
      ),
      AchievementBadge(
        id: 'century',
        title: 'Century',
        desc: 'Log 100 transactions',
        icon: 'hundred',
        color: 0xFF9C27B0,
        // Only count real expenses
        unlocked: realExpenses.length >= 100,
      ),
    ];
  }

  // ── Challenges ────────────────────────────────────────────
  static List<Challenge> challenges(List<Expense> expenses) {
    final now   = DateTime.now();
    final week  = now.subtract(const Duration(days: 7));
    final month = DateTime(now.year, now.month, 1);

    // Only real spending expenses
    final realExpenses = expenses.where((e) =>
        e.isExpense &&
        e.category != 'Savings' &&
        e.category != 'Goals').toList();

    final weekExpenses = realExpenses
        .where((e) => e.date.isAfter(week)).toList();
    final monthExpenses = realExpenses
        .where((e) => e.date.isAfter(month)).toList();

    final foodThisWeek = weekExpenses
        .where((e) => e.category == 'Food')
        .fold(0.0, (s, e) => s + e.amount);
    final entertainmentThisMonth = monthExpenses
        .where((e) => e.category == 'Entertainment')
        .fold(0.0, (s, e) => s + e.amount);
    final budget        = UserService.budget;
    final totalMonthExp = monthExpenses.fold(0.0, (s, e) => s + e.amount);

    // Has the user logged anything this week / month?
    final hasWeekData  = weekExpenses.isNotEmpty;
    final hasMonthData = monthExpenses.isNotEmpty;
    final hasFoodData  = weekExpenses.any((e) => e.category == 'Food');
    final hasEntData   = monthExpenses.any((e) => e.category == 'Entertainment');

    return [
      Challenge(
        id: 'no_food_delivery_week',
        title: 'Cook at Home',
        desc: 'Spend less than ${UserService.currency}200 on food this week',
        icon: Icons_challenge.restaurant,
        color: 0xFF00C853,
        target: 200,
        // Only show real progress if user has logged food this week
        // If no food logged yet, current = target so progress = 0 (not complete)
        current: hasFoodData ? foodThisWeek : 200,
        isLower: true,
        hasData: hasWeekData,
      ),
      Challenge(
        id: 'no_entertainment',
        title: 'Entertainment Fast',
        desc: 'Keep entertainment under ${UserService.currency}500 this month',
        icon: Icons_challenge.movie,
        color: 0xFFFF4081,
        target: 500,
        current: hasEntData ? entertainmentThisMonth : 500,
        isLower: true,
        hasData: hasMonthData,
      ),
      Challenge(
        id: 'budget_80',
        title: 'Budget Champion',
        desc: 'Use only 80% of your monthly budget',
        icon: Icons_challenge.shield,
        color: 0xFF3D5AFE,
        target: budget * 0.8,
        // No data = not started, show 0 progress
        current: hasMonthData ? totalMonthExp : 0,
        isLower: true,
        hasData: hasMonthData && budget > 0,
      ),
      Challenge(
        id: 'streak_7',
        title: '7-Day Streak',
        desc: 'Track expenses every day for 7 days',
        icon: Icons_challenge.fire,
        color: 0xFFFF6D00,
        target: 7,
        current: streak.toDouble(),
        isLower: false,
        hasData: streak > 0,
      ),
      Challenge(
        id: 'save_10pct',
        title: 'Save 10%',
        desc: 'Save 10% of your income this month',
        icon: Icons_challenge.savings,
        color: 0xFF00897B,
        target: UserService.income * 0.1,
        current: UserService.savings,
        isLower: false,
        hasData: UserService.savings > 0,
      ),
    ];
  }
}

// ── Data classes ──────────────────────────────────────────────

class AchievementBadge {
  final String id, title, desc, icon;
  final int color;
  final bool unlocked;
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.unlocked,
  });
}

class Challenge {
  final String id, title, desc;
  final String icon;
  final int color;
  final double target, current;
  final bool isLower;
  final bool hasData; // true = user has relevant data to evaluate this challenge

  const Challenge({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.target,
    required this.current,
    required this.isLower,
    this.hasData = false,
  });

  double get progress {
    // No data = no progress
    if (!hasData) return 0;
    if (target <= 0) return 0;
    if (isLower) {
      return (1 - (current / target)).clamp(0.0, 1.0);
    } else {
      return (current / target).clamp(0.0, 1.0);
    }
  }

  // Only mark complete if user has data AND actually met the condition
  bool get completed => hasData && progress >= 1.0;
}

// Icon string constants for challenges
class Icons_challenge {
  static const restaurant = 'restaurant';
  static const movie      = 'movie';
  static const shield     = 'shield';
  static const fire       = 'fire';
  static const savings    = 'savings';
}
