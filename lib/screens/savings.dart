import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/savings_provider.dart';
import '../services/user_service.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SavingsProvider, ExpenseProvider>(
      builder: (context, savingsProvider, expenseProvider, _) {
        final currency = UserService.currency;
        final savings  = savingsProvider.savings;
        final balance  = expenseProvider.balance;
        final history  = expenseProvider.expenses
            .where((e) => e.category == 'Savings')
            .toList();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Savings',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.savings_rounded,
                            size: 14, color: Color(0xFF00897B)),
                        SizedBox(width: 4),
                        Text('Savings Pot',
                            style: TextStyle(
                                color: Color(0xFF00897B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Savings pot card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF00897B).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Total Savings',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      '$currency${savings.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _actionBtn(
                            label: 'Deposit',
                            icon: Icons.add_rounded,
                            color: Colors.white,
                            textColor: const Color(0xFF00897B),
                            onTap: () => _showDepositSheet(
                                context, savingsProvider,
                                expenseProvider, currency, balance, savings),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionBtn(
                            label: 'Withdraw',
                            icon: Icons.remove_rounded,
                            color: Colors.white.withValues(alpha: 0.15),
                            textColor: Colors.white,
                            onTap: savings > 0
                                ? () => _showWithdrawSheet(
                                    context, savingsProvider,
                                    expenseProvider, currency, savings)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _statCard('Available Balance',
                      '$currency${balance.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_rounded,
                      Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  _statCard('Total Deposited',
                      '$currency${expenseProvider.totalSavingsDeposited.toStringAsFixed(0)}',
                      Icons.arrow_downward_rounded,
                      const Color(0xFF00897B)),
                ],
              ),
              const SizedBox(height: 16),

              // Tip card
              _tipCard(expenseProvider, savingsProvider, currency),
              const SizedBox(height: 20),

              // History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Savings History',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${history.length} entries',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              history.isEmpty
                  ? _emptyHistory()
                  : Column(
                      children: history
                          .map((e) => _historyTile(e, currency))
                          .toList(),
                    ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard(ExpenseProvider ep, SavingsProvider sp, String currency) {
    final savings    = sp.savings;
    final income     = ep.totalIncome;
    final balance    = ep.balance;
    String tip; Color tipColor; IconData tipIcon;

    if (income <= 0) {
      tip = 'Set up your income to get personalised savings tips.';
      tipColor = Colors.grey; tipIcon = Icons.info_outline_rounded;
    } else {
      final pct = (savings / income * 100).clamp(0, 100);
      if (pct >= 20) {
        tip = 'Great job! You\'ve saved ${pct.toStringAsFixed(0)}% of your income.';
        tipColor = const Color(0xFF00C853); tipIcon = Icons.thumb_up_rounded;
      } else if (balance > 0) {
        final suggested = (income * 0.2 - savings).clamp(0, balance);
        tip = 'Save $currency${suggested.toStringAsFixed(0)} more to reach the 20% goal.';
        tipColor = const Color(0xFF00897B); tipIcon = Icons.lightbulb_outline_rounded;
      } else {
        tip = 'Your balance is low. Reduce expenses before saving more.';
        tipColor = const Color(0xFFFF5252); tipIcon = Icons.warning_amber_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tipColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tipColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(tipIcon, color: tipColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tip,
                style: TextStyle(
                    fontSize: 13, color: tipColor, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _historyTile(Expense e, String currency) {
    final isDeposit = e.isExpense;
    final color = isDeposit ? const Color(0xFF00897B) : const Color(0xFFFF6D00);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color, size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isDeposit ? 'Deposited to Savings' : 'Withdrawn from Savings',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  e.note.isEmpty ? _fmtDate(e.date) : '${e.note} · ${_fmtDate(e.date)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isDeposit ? '+' : '-'}$currency${e.amount.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(Icons.savings_outlined, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No savings activity yet',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tap Deposit to start saving',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  // ── Deposit sheet ─────────────────────────────────────────
  void _showDepositSheet(BuildContext context, SavingsProvider sp,
      ExpenseProvider ep, String currency, double balance, double currentSavings) {
    final ctrl     = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Deposit to Savings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Available balance: $currency${balance.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Text(currency, style: const TextStyle(fontSize: 26,
                      fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: ctrl, autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 30,
                          fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey.shade300,
                            fontSize: 30, fontWeight: FontWeight.bold),
                        border: InputBorder.none, filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14)),
              child: TextField(controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)',
                    border: InputBorder.none, filled: false,
                    prefixIcon: Icon(Icons.notes_rounded))),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
              onPressed: () async {
                final amount = double.tryParse(ctrl.text.trim());
                if (amount == null || amount <= 0) {
                  _snack(context, 'Enter a valid amount', error: true); return;
                }
                if (balance <= 0) {
                  _snack(context,
                      'Your balance is empty. Add income before depositing to savings.',
                      error: true); return;
                }
                if (amount > balance) {
                  _snack(context,
                      'Exceeds available balance ($currency${balance.toStringAsFixed(2)})',
                      error: true); return;
                }
                // Deduct from balance via expense transaction
                await ep.addExpense(Expense(
                  amount: amount, category: 'Savings',
                  note: noteCtrl.text.trim(), date: DateTime.now(), isExpense: true,
                ));
                // Update savings pot via provider (persists + notifies)
                await sp.deposit(amount);
                if (ctx.mounted) Navigator.pop(ctx);
                _snack(context,
                    '$currency${amount.toStringAsFixed(0)} deposited to savings',
                    error: false);
              },
              child: const Text('Deposit to Savings'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Withdraw sheet ────────────────────────────────────────
  void _showWithdrawSheet(BuildContext context, SavingsProvider sp,
      ExpenseProvider ep, String currency, double currentSavings) {
    final ctrl     = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Withdraw from Savings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Savings available: $currency${currentSavings.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Text(currency, style: const TextStyle(fontSize: 26,
                      fontWeight: FontWeight.bold, color: Color(0xFFFF6D00))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: ctrl, autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 30,
                          fontWeight: FontWeight.bold, color: Color(0xFFFF6D00)),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey.shade300,
                            fontSize: 30, fontWeight: FontWeight.bold),
                        border: InputBorder.none, filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14)),
              child: TextField(controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)',
                    border: InputBorder.none, filled: false,
                    prefixIcon: Icon(Icons.notes_rounded))),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6D00)),
              onPressed: () async {
                final amount = double.tryParse(ctrl.text.trim());
                if (amount == null || amount <= 0) {
                  _snack(context, 'Enter a valid amount', error: true); return;
                }
                if (amount > currentSavings) {
                  _snack(context,
                      'Exceeds savings ($currency${currentSavings.toStringAsFixed(2)})',
                      error: true); return;
                }
                // Add back to balance as income transaction
                await ep.addExpense(Expense(
                  amount: amount, category: 'Savings',
                  note: noteCtrl.text.trim().isEmpty
                      ? 'Withdrawn from savings' : noteCtrl.text.trim(),
                  date: DateTime.now(), isExpense: false,
                ));
                // Update savings pot via provider
                await sp.withdraw(amount);
                if (ctx.mounted) Navigator.pop(ctx);
                _snack(context,
                    '$currency${amount.toStringAsFixed(0)} withdrawn from savings',
                    error: false);
              },
              child: const Text('Withdraw'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg, {required bool error}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFFF5252) : const Color(0xFF00897B),
      ));
}


