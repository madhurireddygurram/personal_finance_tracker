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

    if (income <= 0) return 0;

    // 1. Savings rate (max 40 pts) — 20% savings = full 40 pts
    final savingsRate = (savings / income).clamp(0.0, 0.2);
    score += (savingsRate / 0.2 * 40).toInt();

    // 2. Budget adherence (max 30 pts)
    if (budget > 0) {
      final totalExp = expenses
          .where((e) => e.isExpense && e.category != 'Savings' && e.category != 'Goals')
          .fold(0.0, (s, e) => s + e.amount);
      final ratio = (totalExp / budget).clamp(0.0, 2.0);
      if (ratio <= 1.0) score += (30 * (1 - ratio * 0.5)).toInt();
    }

    // 3. Streak bonus (max 20 pts) — 30-day streak = full 20 pts
    score += (streak.clamp(0, 30) / 30 * 20).toInt();

    // 4. Has savings at all (10 pts)
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
    final totalExp = expenses
        .where((e) => e.isExpense && e.category != 'Savings' && e.category != 'Goals')
        .fold(0.0, (s, e) => s + e.amount);

    return [
      AchievementBadge(
        id: 'first_expense',
        title: 'First Step',
        desc: 'Log your first expense',
        icon: 'wallet',
        color: 0xFF00C853,
        unlocked: expenses.isNotEmpty,
      ),
      AchievementBadge(
        id: 'saver',
        title: 'Saver',
        desc: 'Save at least 10% of income',
        icon: 'savings',
        color: 0xFF00897B,
        unlocked: income > 0 && savings >= income * 0.1,
      ),
      AchievementBadge(
        id: 'super_saver',
        title: 'Super Saver',
        desc: 'Save at least 20% of income',
        icon: 'star',
        color: 0xFFFFD700,
        unlocked: income > 0 && savings >= income * 0.2,
      ),
      AchievementBadge(
        id: 'budget_master',
        title: 'Budget Master',
        desc: 'Stay within budget this month',
        icon: 'shield',
        color: 0xFF3D5AFE,
        unlocked: budget > 0 && totalExp <= budget,
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
        desc: 'Stay under budget for a full month',
        icon: 'check',
        color: 0xFF00BCD4,
        unlocked: budget > 0 && totalExp < budget * 0.9,
      ),
      AchievementBadge(
        id: 'diversified',
        title: 'Diversified',
        desc: 'Track expenses in 5+ categories',
        icon: 'chart',
        color: 0xFFFF4081,
        unlocked: expenses.map((e) => e.category).toSet().length >= 5,
      ),
      AchievementBadge(
        id: 'century',
        title: 'Century',
        desc: 'Log 100 transactions',
        icon: 'hundred',
        color: 0xFF9C27B0,
        unlocked: expenses.length >= 100,
      ),
    ];
  }

  // ── Challenges ────────────────────────────────────────────
  static List<Challenge> challenges(List<Expense> expenses) {
    final now   = DateTime.now();
    final week  = now.subtract(const Duration(days: 7));
    final month = DateTime(now.year, now.month, 1);

    final weekExpenses = expenses.where(
        (e) => e.isExpense && e.date.isAfter(week)).toList();
    final monthExpenses = expenses.where(
        (e) => e.isExpense && e.date.isAfter(month)).toList();

    final foodThisWeek = weekExpenses
        .where((e) => e.category == 'Food')
        .fold(0.0, (s, e) => s + e.amount);
    final entertainmentThisMonth = monthExpenses
        .where((e) => e.category == 'Entertainment')
        .fold(0.0, (s, e) => s + e.amount);
    final budget = UserService.budget;
    final totalMonthExp = monthExpenses.fold(0.0, (s, e) => s + e.amount);

    return [
      Challenge(
        id: 'no_food_delivery_week',
        title: 'Cook at Home',
        desc: 'Spend less than ${UserService.currency}200 on food this week',
        icon: Icons_challenge.restaurant,
        color: 0xFF00C853,
        target: 200,
        current: foodThisWeek,
        isLower: true,
      ),
      Challenge(
        id: 'no_entertainment',
        title: 'Entertainment Fast',
        desc: 'Keep entertainment under ${UserService.currency}500 this month',
        icon: Icons_challenge.movie,
        color: 0xFFFF4081,
        target: 500,
        current: entertainmentThisMonth,
        isLower: true,
      ),
      Challenge(
        id: 'budget_80',
        title: 'Budget Champion',
        desc: 'Use only 80% of your monthly budget',
        icon: Icons_challenge.shield,
        color: 0xFF3D5AFE,
        target: budget * 0.8,
        current: totalMonthExp,
        isLower: true,
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
  final bool isLower; // true = lower is better (spending), false = higher is better (saving)

  const Challenge({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.target,
    required this.current,
    required this.isLower,
  });

  double get progress {
    if (target <= 0) return 0;
    if (isLower) {
      return (1 - (current / target)).clamp(0.0, 1.0);
    } else {
      return (current / target).clamp(0.0, 1.0);
    }
  }

  bool get completed => progress >= 1.0;
}

// Icon string constants for challenges
class Icons_challenge {
  static const restaurant = 'restaurant';
  static const movie      = 'movie';
  static const shield     = 'shield';
  static const fire       = 'fire';
  static const savings    = 'savings';
}
