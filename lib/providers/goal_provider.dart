import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';
import 'expense_provider.dart';

class GoalProvider extends ChangeNotifier {
  List<Goal> _goals = [];

  List<Goal> get goals => _goals;

  // Total amount saved across all goals
  double get totalSaved => _goals.fold(0.0, (s, g) => s + g.savedAmount);

  void loadGoals() {
    _goals = HiveService.getAllGoals();
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    await HiveService.addGoal(goal);
    loadGoals();
  }

  Future<void> deleteGoal(Goal goal) async {
    await HiveService.deleteGoal(goal);
    loadGoals();
  }

  Future<void> updateGoal(Goal goal) async {
    await HiveService.updateGoal(goal);
    loadGoals();
  }

  // Add money to a goal AND deduct from balance via an expense transaction
  Future<void> addMoney(
      Goal goal, double amount, ExpenseProvider expenseProvider) async {
    // 1. Update goal saved amount
    goal.savedAmount =
        (goal.savedAmount + amount).clamp(0, goal.targetAmount);
    await HiveService.updateGoal(goal);

    // 2. Record as an expense so balance decreases automatically
    await expenseProvider.addExpense(Expense(
      amount   : amount,
      category : 'Goals',
      note     : 'Saved for: ${goal.name}',
      date     : DateTime.now(),
      isExpense: true,
    ));

    loadGoals();
  }
}
