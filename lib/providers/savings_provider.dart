import 'package:flutter/material.dart';
import '../services/user_service.dart';

class SavingsProvider extends ChangeNotifier {
  double _savings = 0;

  double get savings => _savings;

  void load() {
    _savings = UserService.savings;
    notifyListeners();
  }

  Future<void> deposit(double amount) async {
    _savings += amount;
    await UserService.updateSavings(_savings);
    notifyListeners();
  }

  Future<void> withdraw(double amount) async {
    _savings = (_savings - amount).clamp(0, double.infinity);
    await UserService.updateSavings(_savings);
    notifyListeners();
  }
}
