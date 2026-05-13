import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';
import '../services/user_service.dart';
import '../services/gamification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  List<Expense> get onlyExpenses =>
      _expenses.where((e) => e.isExpense).toList();

  List<Expense> get onlyIncome =>
      _expenses.where((e) => !e.isExpense).toList();

  double get totalExpenses =>
      onlyExpenses.fold(0, (sum, e) => sum + e.amount);

  // Transaction income (manually added income entries)
  double get transactionIncome =>
      onlyIncome.fold(0, (sum, e) => sum + e.amount);

  // Setup income is the user's monthly income entered during onboarding.
  // It acts as the starting balance — balance = setupIncome + transactionIncome - expenses
  double get balance =>
      UserService.income + transactionIncome - totalExpenses;

  // "Total Income" shown on dashboard = setup income + any added income transactions
  double get totalIncome => UserService.income + transactionIncome;

  void loadExpenses() {
    _expenses = HiveService.getAllExpenses();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await HiveService.addExpense(expense);
    await GamificationService.recordActivity(); // update streak
    loadExpenses();
  }

  Future<void> deleteExpense(Expense expense) async {
    await HiveService.deleteExpense(expense);
    loadExpenses();
  }

  // Update an existing expense in-place
  Future<void> updateExpense(Expense expense) async {
    await HiveService.updateExpense(expense);
    loadExpenses();
  }

  // Grouped by date label for the transactions screen
  Map<String, List<Expense>> get groupedExpenses {
    final Map<String, List<Expense>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    for (final e in _expenses) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      String label;
      if (d == today) {
        label = 'Today';
      } else if (d == yesterday) {
        label = 'Yesterday';
      } else {
        label = '${e.date.day} ${months[e.date.month - 1]}';
      }
      grouped.putIfAbsent(label, () => []).add(e);
    }
    return grouped;
  }

  // Per-category expense totals for pie chart
  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};
    for (final e in onlyExpenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  // Total amount set aside for goals (category == 'Goals')
  double get totalGoalSavings => onlyExpenses
      .where((e) => e.category == 'Goals')
      .fold(0.0, (s, e) => s + e.amount);

  // Total deposited into savings pot (category == 'Savings', isExpense=true)
  double get totalSavingsDeposited => onlyExpenses
      .where((e) => e.category == 'Savings')
      .fold(0.0, (s, e) => s + e.amount);

  // Savings withdrawals are income entries with category == 'Savings'
  double get totalSavingsWithdrawn => onlyIncome
      .where((e) => e.category == 'Savings')
      .fold(0.0, (s, e) => s + e.amount);
}
