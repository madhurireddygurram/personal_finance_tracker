import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/goal.dart';

class HiveService {
  static const String _expenseBox = 'expenses';
  static const String _goalBox = 'goals';

  static Future<void> init() async {
    // initFlutter() handles all platforms:
    // - Web: uses IndexedDB (persistent across sessions)
    // - Android/iOS: uses app documents directory
    // - Windows/macOS/Linux: uses app support directory
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(expenseTypeId)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(goalTypeId)) {
      Hive.registerAdapter(GoalAdapter());
    }

    if (!Hive.isBoxOpen(_expenseBox)) {
      await Hive.openBox<Expense>(_expenseBox);
    }
    if (!Hive.isBoxOpen(_goalBox)) {
      await Hive.openBox<Goal>(_goalBox);
    }
  }

  // ── Expense operations ────────────────────────────────────
  static Box<Expense> get _expenses => Hive.box<Expense>(_expenseBox);

  static Future<void> addExpense(Expense expense) async {
    await _expenses.add(expense);
    await _expenses.flush();
  }

  static List<Expense> getAllExpenses() {
    final list = _expenses.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> deleteExpense(Expense expense) async {
    await expense.delete();
    await _expenses.flush();
  }

  static Future<void> updateExpense(Expense expense) async {
    await expense.save(); // HiveObject.save() writes changes in-place
    await _expenses.flush();
  }

  // ── Goal operations ───────────────────────────────────────
  static Box<Goal> get _goals => Hive.box<Goal>(_goalBox);

  static Future<void> addGoal(Goal goal) async {
    await _goals.add(goal);
    await _goals.flush();
  }

  static List<Goal> getAllGoals() {
    return _goals.values.toList();
  }

  static Future<void> deleteGoal(Goal goal) async {
    await goal.delete();
    await _goals.flush();
  }

  static Future<void> updateGoal(Goal goal) async {
    await goal.save();
    await _goals.flush();
  }
}
