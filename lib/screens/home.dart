import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'transactions.dart';
import 'quick_scan.dart';
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

  // 0=Home, 1=Txns, 2=Scan, FAB=center, 3=Savings, 4=Goals, 5=Profile
  final _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    QuickScanScreen(),
    SizedBox.shrink(), // FAB placeholder
    SavingsScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: _index == 3 ? _screens[0] : _screens[_index],
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
            _navItem(Icons.home_rounded,             'Home',    0, primary),
            _navItem(Icons.receipt_long_rounded,     'Txns',    1, primary),
            _navItem(Icons.document_scanner_rounded, 'Scan',    2, primary),
            const SizedBox(width: 48), // FAB notch
            _navItem(Icons.savings_rounded,          'Savings', 4, primary),
            _navItem(Icons.flag_rounded,             'Goals',   5, primary),
            _navItem(Icons.person_rounded,           'Profile', 6, primary),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? primary : Colors.grey, size: 22),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: active ? primary : Colors.grey,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
