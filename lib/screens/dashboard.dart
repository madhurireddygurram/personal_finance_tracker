import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/savings_provider.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../services/user_service.dart';
import '../services/gamification_service.dart';
import 'ai_assistant.dart';
import 'analytics.dart';
import '../l10n/app_localizations.dart';
import 'gamification.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  static const _catIcons = <String, IconData>{
    'Food'         : Icons.restaurant_rounded,
    'Transport'    : Icons.directions_car_rounded,
    'Shopping'     : Icons.shopping_bag_rounded,
    'Bills'        : Icons.receipt_long_rounded,
    'Health'       : Icons.favorite_rounded,
    'Education'    : Icons.school_rounded,
    'Entertainment': Icons.movie_rounded,
    'Income'       : Icons.account_balance_rounded,
    'Goals'        : Icons.flag_rounded,
    'Savings'      : Icons.savings_rounded,
    'Other'        : Icons.category_rounded,
  };

  static const _catColors = {
    'Food'         : Color(0xFF00C853),
    'Transport'    : Color(0xFF7C4DFF),
    'Shopping'     : Color(0xFFFF6D00),
    'Bills'        : Color(0xFFFF5252),
    'Health'       : Color(0xFF00BCD4),
    'Education'    : Color(0xFF3D5AFE),
    'Entertainment': Color(0xFFFF4081),
    'Income'       : Color(0xFF00C853),
    'Goals'        : Color(0xFF00897B),
    'Savings'      : Color(0xFF00897B),
    'Other'        : Color(0xFF9E9E9E),
  };

  // Income source labels
  static const _incomeSources = [
    'Pocket Money', 'Salary', 'Gift', 'Freelance',
    'Part-time Job', 'Bonus', 'Scholarship', 'Refund', 'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExpenseProvider, GoalProvider, SavingsProvider>(
      builder: (context, provider, goalProvider, savingsProvider, _) {
        final currency = UserService.currency;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _topBar(),
              const SizedBox(height: 12),
              _gamificationBar(provider),
              const SizedBox(height: 16),
              _balanceCard(provider, currency),
              const SizedBox(height: 16),
              _incomeCard(provider, currency),
              const SizedBox(height: 16),
              _savingsCard(provider, savingsProvider, currency),
              const SizedBox(height: 16),
              _budgetRow(provider, currency),
              const SizedBox(height: 20),
              _sectionTitle('Spending Overview', onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
              const SizedBox(height: 12),
              _chartCard(provider),
              const SizedBox(height: 20),
              _insightCard(provider, currency),
              const SizedBox(height: 20),
              _smartTrends(provider, currency),
              const SizedBox(height: 20),
              _sectionTitle('Goals', onTap: () {}),
              const SizedBox(height: 12),
              _goalsPreview(goalProvider, currency),
              const SizedBox(height: 20),
              _sectionTitle('Recent Transactions', onTap: () {}),
              const SizedBox(height: 12),
              _recentTransactions(provider, currency),
              const SizedBox(height: 20),
              _quickActions(context),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Top bar ───────────────────────────────────────────────
  Widget _topBar() {
    final name = UserService.name;
    final firstName = name.contains(' ') ? name.split(' ').first : name;
    final l   = AppLocalizations.of(context);
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l.hello}, $firstName',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
        IconButton(icon: const Icon(Icons.notifications_outlined, size: 26), onPressed: () {}),
      ],
    );
  }

  // ── Gamification bar ──────────────────────────────────────
  Widget _gamificationBar(ExpenseProvider p) {
    final primary    = Theme.of(context).colorScheme.primary;
    final streak     = GamificationService.streak;
    final score      = GamificationService.savingsScore(p.expenses);
    final label      = GamificationService.scoreLabel(score);
    final scoreColor = score >= 70 ? primary
        : score >= 40 ? const Color(0xFFFF6D00)
            : const Color(0xFFFF5252);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const GamificationScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFF6D00), size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$streak day streak',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Log daily to grow!',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
            const Spacer(),
            Container(width: 1, height: 32, color: Colors.grey.shade200),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Score: $score',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: scoreColor)),
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.emoji_events_rounded,
                  color: scoreColor, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Balance card — income from setup is the starting balance ──
  Widget _balanceCard(ExpenseProvider p, String currency) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          const Text('Total Balance',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(
            '$currency${p.balance.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _balanceStat(
                  'Income',
                  '$currency${p.totalIncome.toStringAsFixed(0)}',
                  Icons.arrow_downward_rounded,
                  Colors.white),
              Container(width: 1, height: 32, color: Colors.white24),
              _balanceStat(
                  'Expenses',
                  '$currency${p.totalExpenses.toStringAsFixed(0)}',
                  Icons.arrow_upward_rounded,
                  Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceStat(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.7), fontSize: 11)),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ],
    );
  }

  // ── Income breakdown card ─────────────────────────────────
  Widget _incomeCard(ExpenseProvider p, String currency) {
    final isStudent   = UserService.isStudent;
    final setupIncome = UserService.income;
    final extraIncome = p.transactionIncome;
    final totalIncome = p.totalIncome;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF00C853), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Income Breakdown',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              GestureDetector(
                onTap: () => _showAddIncome(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Add Income',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _incomeRow(
            isStudent ? 'Monthly Pocket Money' : 'Monthly Salary',
            '$currency${setupIncome.toStringAsFixed(0)}',
            Icons.calendar_month_rounded,
            Theme.of(context).colorScheme.primary,
          ),
          if (extraIncome > 0) ...[
            const SizedBox(height: 8),
            _incomeRow(
              'Extra Income Added',
              '+$currency${extraIncome.toStringAsFixed(0)}',
              Icons.add_circle_outline_rounded,
              const Color(0xFF7C4DFF),
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Income',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text('$currency${totalIncome.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF00C853))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _incomeRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13))),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color)),
      ],
    );
  }

  // ── Add Income bottom sheet ───────────────────────────────
  void _showAddIncome(ExpenseProvider provider) {
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController();
    String selSource = _incomeSources.first;
    final currency   = UserService.currency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Add Extra Income',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Got extra money? Add it here and your balance updates automatically.',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      height: 1.4),
                ),
                const SizedBox(height: 20),

                // Amount
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Text(currency,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C853))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          autofocus: true,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C853)),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 30,
                                fontWeight: FontWeight.bold),
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Source chips
                const Text('Source',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _incomeSources.map((src) {
                    final active = selSource == src;
                    return GestureDetector(
                      onTap: () => setSheet(() => selSource = src),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: active
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade200),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                      color: Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ]
                              : [],
                        ),
                        child: Text(src,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : Colors.grey.shade700)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Note
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: InputBorder.none,
                      filled: false,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save
                ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    final note = noteCtrl.text.trim().isEmpty
                        ? selSource
                        : noteCtrl.text.trim();
                    await provider.addExpense(Expense(
                      amount   : amount,
                      category : 'Income',
                      note     : note,
                      date     : DateTime.now(),
                      isExpense: false,
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '$currency$amount added as $selSource'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }
                  },
                  child: const Text('Add to Balance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Savings summary card ──────────────────────────────────
  Widget _savingsCard(ExpenseProvider p, SavingsProvider sp, String currency) {
    final savings    = sp.savings;
    final income     = p.totalIncome;
    final savingsPct = income > 0 ? (savings / income * 100).clamp(0, 100) : 0.0;

    return GestureDetector(
      onTap: () {
        // Navigate to savings tab (index 3 in home)
          },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF004D40)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.savings_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Savings Pot',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    income > 0
                        ? '${savingsPct.toStringAsFixed(1)}% of income saved'
                        : 'Tap Savings tab to manage',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency${savings.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF00897B)),
                ),
                const SizedBox(height: 2),
                const Text('saved',
                    style: TextStyle(
                        color: Color(0xFF00897B), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Budget progress bar ───────────────────────────────────
  Widget _budgetRow(ExpenseProvider p, String currency) {
    final budget     = UserService.budget;
    final spent      = p.totalExpenses;
    final progress   = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final overBudget = spent > budget && budget > 0;
    final pct        = budget > 0 ? (spent / budget * 100) : 0.0;
    // Alert levels
    final at90  = pct >= 90 && pct < 100;
    final at80  = pct >= 80 && pct < 90;
    final at50  = pct >= 50 && pct < 80;

    Color barColor;
    if (overBudget)   barColor = const Color(0xFFFF5252);
    else if (at90)    barColor = const Color(0xFFFF5252);
    else if (at80)    barColor = const Color(0xFFFF6D00);
    else              barColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: overBudget || at90
            ? Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.4))
            : at80
                ? Border.all(color: const Color(0xFFFF6D00).withValues(alpha: 0.4))
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Budget',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                overBudget
                    ? 'Over budget!'
                    : '$currency${spent.toStringAsFixed(0)} / $currency${budget.toStringAsFixed(0)}',
                style: TextStyle(
                    color: overBudget || at90
                        ? const Color(0xFFFF5252)
                        : at80
                            ? const Color(0xFFFF6D00)
                            : Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: overBudget || at90 || at80
                        ? FontWeight.w600
                        : FontWeight.normal),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 8),
          // Alert messages at different thresholds
          if (budget == 0)
            Text('Set your budget in Setup or Profile',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12))
          else if (overBudget)
            _budgetAlert(
              Icons.warning_rounded,
              const Color(0xFFFF5252),
              'Budget exceeded by $currency${(spent - budget).toStringAsFixed(0)}! Review your spending.',
            )
          else if (at90)
            _budgetAlert(
              Icons.warning_amber_rounded,
              const Color(0xFFFF5252),
              'Only $currency${(budget - spent).toStringAsFixed(0)} left! You\'ve used ${pct.toStringAsFixed(0)}% of your budget.',
            )
          else if (at80)
            _budgetAlert(
              Icons.info_outline_rounded,
              const Color(0xFFFF6D00),
              'Heads up! You\'ve used ${pct.toStringAsFixed(0)}% of your budget. Slow down spending.',
            )
          else if (at50)
            _budgetAlert(
              Icons.check_circle_outline_rounded,
              Theme.of(context).colorScheme.primary,
              '$currency${(budget - spent).toStringAsFixed(0)} remaining — you\'re on track!',
            ),
        ],
      ),
    );
  }

  Widget _budgetAlert(IconData icon, Color color, String msg) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(msg,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: onTap,
          child: const Text('See all',
              style:
                  TextStyle(color: Color(0xFF00C853), fontSize: 13)),
        ),
      ],
    );
  }

  // ── Pie chart ─────────────────────────────────────────────
  Widget _chartCard(ExpenseProvider p) {
    final totals = p.categoryTotals;
    if (totals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No expenses yet',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Add a transaction to see your spending breakdown',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    final total = totals.values.fold(0.0, (a, b) => a + b);
    final sections = totals.entries.map((e) {
      final pct = e.value / total * 100;
      final color = _catColors[e.key] ?? Colors.grey;
      return PieChartSectionData(
        value: e.value,
        color: color,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 52,
        titleStyle: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spending by Category',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 34,
                    sections: sections,
                  )),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: totals.keys
                        .map((cat) => _legend(
                            cat, _catColors[cat] ?? Colors.grey))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ── Smart insight card ────────────────────────────────────
  Widget _insightCard(ExpenseProvider p, String currency) {
    final insights = _buildInsights(p, currency);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF7C4DFF), size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Smart Insights',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C4DFF),
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item['icon'] as IconData,
                        size: 15, color: item['color'] as Color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item['text'] as String,
                          style: const TextStyle(
                              fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildInsights(
      ExpenseProvider p, String currency) {
    if (p.expenses.isEmpty) {
      return [
        {
          'icon': Icons.info_outline_rounded,
          'color': Colors.grey,
          'text': 'Add your first transaction to see insights here.',
        }
      ];
    }
    final insights = <Map<String, dynamic>>[];
    final totals = p.categoryTotals;
    final budget = UserService.budget;

    if (totals.isNotEmpty) {
      final top =
          totals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add({
        'icon': _catIcons[top.key] ?? Icons.category_rounded,
        'color': _catColors[top.key] ?? Colors.grey,
        'text':
            'Highest spending: ${top.key} at $currency${top.value.toStringAsFixed(0)}',
      });
    }
    if (budget > 0) {
      final remaining = budget - p.totalExpenses;
      if (remaining < 0) {
        insights.add({
          'icon': Icons.warning_amber_rounded,
          'color': const Color(0xFFFF5252),
          'text':
              'You have exceeded your budget by $currency${(-remaining).toStringAsFixed(0)}.',
        });
      } else {
        insights.add({
          'icon': Icons.check_circle_outline_rounded,
          'color': Theme.of(context).colorScheme.primary,
          'text':
              '$currency${remaining.toStringAsFixed(0)} remaining from your monthly budget.',
        });
      }
    }
    if (p.totalIncome > 0) {
      final savePct = ((p.balance / p.totalIncome) * 100)
          .clamp(0, 100)
          .toStringAsFixed(0);
      insights.add({
        'icon': Icons.savings_outlined,
        'color': const Color(0xFF00897B),
        'text': 'You are saving $savePct% of your income this month.',
      });
    }
    return insights;
  }

  // ── Goals preview — only user-created goals ───────────────
  // ── Smart Trends ───────────────────────────────────────────────
  Widget _smartTrends(ExpenseProvider p, String currency) {
    final expenses = p.onlyExpenses;
    final primary  = Theme.of(context).colorScheme.primary;

    // Show teaser card when no expenses yet
    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.show_chart_rounded, color: primary, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('Smart Trends',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Unlocks with data',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Skeleton preview bars
            Text('7-Day Spending',
                style: TextStyle(color: Colors.grey.shade400,
                    fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            // Fake skeleton chart
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0.3, 0.6, 0.4, 0.8, 0.5, 0.7, 0.45]
                    .map((h) => Container(
                          width: 28,
                          height: 80 * h,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Skeleton stat row
            Row(
              children: [
                _trendStat('Daily Avg', '—', Icons.today_rounded,
                    Colors.grey.shade300),
                _trendDivider(),
                _trendStat('This Week', '—', Icons.date_range_rounded,
                    Colors.grey.shade300),
                _trendDivider(),
                _trendStat('Projected', '—', Icons.trending_up_rounded,
                    Colors.grey.shade300),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      color: primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add your first transaction to unlock spending trends, daily averages, and category insights.',
                      style: TextStyle(
                          color: primary, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final now     = DateTime.now();

    // ── 7-day daily spending data ─────────────────────────
    final List<double> dailySpend = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      return expenses
          .where((e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold(0.0, (s, e) => s + e.amount);
    });

    // ── Category totals this month ────────────────────────
    final month = DateTime(now.year, now.month, 1);
    final catTotals = <String, double>{};
    for (final e in expenses.where((e) => e.date.isAfter(month))) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCats = sortedCats.take(4).toList();
    final catMax  = topCats.isEmpty ? 1.0 : topCats.first.value;

    // ── Trend summary stats ───────────────────────────────
    final thisWeekTotal = dailySpend.fold(0.0, (s, v) => s + v);
    final dailyAvg      = thisWeekTotal / 7;
    final budget        = UserService.budget;
    final monthSpend    = expenses
        .where((e) => e.date.isAfter(month))
        .fold(0.0, (s, e) => s + e.amount);
    final projected     = now.day > 0 ? (monthSpend / now.day) * 30 : 0.0;

    const dayLabels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    // Map today's weekday to the last label
    final startOffset = (now.weekday - 1) % 7;
    final labels = List.generate(7,
        (i) => dayLabels[(startOffset - 6 + i + 7) % 7]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.show_chart_rounded, color: primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('Smart Trends',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              // Projected badge
              if (budget > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: projected > budget
                        ? const Color(0xFFFF5252).withValues(alpha: 0.1)
                        : primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    projected > budget ? 'Over projected' : 'On track',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: projected > budget
                            ? const Color(0xFFFF5252)
                            : primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 7-day line chart ──────────────────────────
          Text('7-Day Spending',
              style: TextStyle(color: Colors.grey.shade500,
                  fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length)
                          return const SizedBox.shrink();
                        return Text(labels[i],
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 9));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(7,
                        (i) => FlSpot(i.toDouble(), dailySpend[i])),
                    isCurved: true,
                    color: primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                              radius: 3,
                              color: primary,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primary.withValues(alpha: 0.2),
                          primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats row ─────────────────────────────────
          Row(
            children: [
              _trendStat('Daily Avg',
                  '$currency${dailyAvg.toStringAsFixed(0)}',
                  Icons.today_rounded, primary),
              _trendDivider(),
              _trendStat('This Week',
                  '$currency${thisWeekTotal.toStringAsFixed(0)}',
                  Icons.date_range_rounded, const Color(0xFF7C4DFF)),
              _trendDivider(),
              _trendStat('Projected',
                  '$currency${projected.toStringAsFixed(0)}',
                  Icons.trending_up_rounded,
                  projected > budget && budget > 0
                      ? const Color(0xFFFF5252)
                      : primary),
            ],
          ),

          if (topCats.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 12),

            // ── Category mini bars ────────────────────
            Text('Top Categories This Month',
                style: TextStyle(color: Colors.grey.shade500,
                    fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ...topCats.map((entry) {
              final color = _catColors[entry.key] ?? Colors.grey;
              final pct   = catMax > 0 ? entry.value / catMax : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(entry.key,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$currency${entry.value.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _trendStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _trendDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.shade200);

  Widget _goalsPreview(GoalProvider gp, String currency) {
    if (gp.goals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(Icons.flag_outlined,
                color: Colors.grey.shade300, size: 28),
            const SizedBox(width: 12),
            Text('No goals yet. Add one in the Goals tab.',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: gp.goals.take(2).map((goal) => _goalTile(goal, currency)).toList(),
    );
  }

  Widget _goalTile(Goal goal, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(goal.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                '${(goal.progress * 100).toInt()}%',
                style: const TextStyle(
                    color: Color(0xFF00C853),
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF00C853)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$currency${goal.savedAmount.toStringAsFixed(0)} / $currency${goal.targetAmount.toStringAsFixed(0)}',
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Recent transactions ───────────────────────────────────
  Widget _recentTransactions(ExpenseProvider p, String currency) {
    if (p.expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('No transactions yet',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tap the + button to add one',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }
    return Column(
      children: p.expenses
          .take(5)
          .map((e) => _txnTile(e, currency))
          .toList(),
    );
  }

  Widget _txnTile(Expense e, String currency) {
    final color = _catColors[e.category] ?? Colors.grey;
    final icon = _catIcons[e.category] ?? Icons.category_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.note.isEmpty ? e.category : e.note,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                Text(e.category,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${e.isExpense ? '-' : '+'}$currency${e.amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: e.isExpense
                    ? const Color(0xFFFF5252)
                    : Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────
  Widget _quickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionBtn(context, Icons.mic_rounded, 'Voice',
                Theme.of(context).colorScheme.primary, () {}),
            _actionBtn(context, Icons.camera_alt_rounded, 'Scan',
                const Color(0xFF7C4DFF), () {}),
            _actionBtn(context, Icons.chat_rounded, 'AI Chat',
                const Color(0xFFFF6D00), () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AiAssistantScreen()));
            }),
            _actionBtn(context, Icons.bar_chart_rounded, 'Analytics',
                const Color(0xFF00BCD4), () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AnalyticsScreen()));
            }),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}







