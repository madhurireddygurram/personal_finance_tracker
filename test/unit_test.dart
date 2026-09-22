import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/models/expense.dart';
import 'package:personal_finance_tracker/models/goal.dart';
import 'package:personal_finance_tracker/services/user_service.dart';

void main() {
  group('Expense Model Tests', () {
    test('creates expense instance correctly', () {
      final now = DateTime.now();
      final expense = Expense(
        amount: 250.75,
        category: 'Food',
        note: 'Lunch at cafe',
        date: now,
        isExpense: true,
      );

      expect(expense.amount, 250.75);
      expect(expense.category, 'Food');
      expect(expense.note, 'Lunch at cafe');
      expect(expense.date, now);
      expect(expense.isExpense, isTrue);
    });

    test('creates income instance correctly', () {
      final now = DateTime.now();
      final income = Expense(
        amount: 50000.0,
        category: 'Salary',
        note: 'Monthly salary',
        date: now,
        isExpense: false,
      );

      expect(income.amount, 50000.0);
      expect(income.category, 'Salary');
      expect(income.isExpense, isFalse);
    });

    test('ExpenseAdapter has expected typeId', () {
      final adapter = ExpenseAdapter();
      expect(adapter.typeId, expenseTypeId);
      expect(adapter.typeId, 0);
    });
  });

  group('Goal Model Tests', () {
    test('calculates progress accurately', () {
      final deadline = DateTime.now().add(const Duration(days: 30));
      final goal = Goal(
        name: 'New Phone',
        targetAmount: 20000.0,
        savedAmount: 5000.0,
        deadline: deadline,
      );

      expect(goal.progress, 0.25);
      expect(goal.isCompleted, isFalse);
    });

    test('progress clamps to 1.0 when saved exceeds target', () {
      final deadline = DateTime.now().add(const Duration(days: 30));
      final goal = Goal(
        name: 'Emergency Fund',
        targetAmount: 10000.0,
        savedAmount: 15000.0,
        deadline: deadline,
      );

      expect(goal.progress, 1.0);
      expect(goal.isCompleted, isTrue);
    });

    test('progress handles zero target amount gracefully', () {
      final deadline = DateTime.now().add(const Duration(days: 30));
      final goal = Goal(
        name: 'Zero Target',
        targetAmount: 0.0,
        savedAmount: 50.0,
        deadline: deadline,
      );

      expect(goal.progress, 0.0);
    });

    test('GoalAdapter has expected typeId', () {
      final adapter = GoalAdapter();
      expect(adapter.typeId, goalTypeId);
      expect(adapter.typeId, 1);
    });
  });

  group('Authentication & User Model Tests', () {
    test('AuthResult values exist and are distinct', () {
      expect(AuthResult.values.length, 3);
      expect(AuthResult.values.contains(AuthResult.success), isTrue);
      expect(AuthResult.values.contains(AuthResult.wrongPassword), isTrue);
      expect(AuthResult.values.contains(AuthResult.userNotFound), isTrue);
    });
  });
}

