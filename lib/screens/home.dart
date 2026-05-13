import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'transactions.dart';
import 'add_expense.dart';
import 'goals.dart';
import 'savings.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    SizedBox.shrink(),
    SavingsScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: _screens[_index],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        backgroundColor: primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 'Home', 0, primary),
            _navItem(Icons.receipt_long_rounded, 'Txns', 1, primary),
            const SizedBox(width: 48),
            _navItem(Icons.savings_rounded, 'Savings', 3, primary),
            _navItem(Icons.flag_rounded, 'Goals', 4, primary),
            _navItem(Icons.person_rounded, 'Profile', 5, primary),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int i, Color primary) {
    final active = _index == i;
    return InkWell(
      onTap: () => setState(() => _index = i),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? primary : Colors.grey, size: 22),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: active ? primary : Colors.grey,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

