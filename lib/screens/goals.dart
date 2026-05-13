import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart';
import '../providers/expense_provider.dart';
import '../services/user_service.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  static const _goalColors = [
    Color(0xFF00C853),
    Color(0xFF7C4DFF),
    Color(0xFFFF6D00),
    Color(0xFF00BCD4),
    Color(0xFF3D5AFE),
    Color(0xFFFF4081),
  ];

  Color _colorFor(int index) => _goalColors[index % _goalColors.length];

  @override
  Widget build(BuildContext context) {
    return Consumer2<GoalProvider, ExpenseProvider>(
      builder: (context, provider, expenseProvider, _) {
        final currency = UserService.currency;
        return SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Goals',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    FilledButton.icon(
                      onPressed: () => _showAddGoal(context, provider, currency),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Goal'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (provider.goals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _summaryBar(provider, expenseProvider, currency),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: provider.goals.isEmpty
                    ? _emptyState(context, provider, currency)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.goals.length,
                        itemBuilder: (_, i) => _goalCard(
                          context, provider, expenseProvider,
                          provider.goals[i], _colorFor(i), currency,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Summary bar ───────────────────────────────────────────
  Widget _summaryBar(GoalProvider provider, ExpenseProvider expenseProvider, String currency) {
    final total     = provider.goals.fold(0.0, (s, g) => s + g.targetAmount);
    final saved     = provider.goals.fold(0.0, (s, g) => s + g.savedAmount);
    final completed = provider.goals.where((g) => g.isCompleted).length;
    final deducted  = expenseProvider.totalGoalSavings;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00C853).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF00C853).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total Goals', '${provider.goals.length}',
              Icons.flag_rounded, const Color(0xFF00C853)),
          _vDivider(),
          _summaryItem('Saved', '$currency${saved.toStringAsFixed(0)}',
              Icons.savings_outlined, const Color(0xFF7C4DFF)),
          _vDivider(),
          _summaryItem('From Balance', '-$currency${deducted.toStringAsFixed(0)}',
              Icons.account_balance_wallet_outlined, const Color(0xFFFF5252)),
          _vDivider(),
          _summaryItem('Done', '$completed',
              Icons.check_circle_outline_rounded, const Color(0xFF00BCD4)),
        ],
      ),
    );
  }

  Widget _summaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.shade200);

  // ── Goal card ─────────────────────────────────────────────
  Widget _goalCard(BuildContext context, GoalProvider provider,
      ExpenseProvider expenseProvider, Goal goal, Color color, String currency) {
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0 && !goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.flag_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      goal.isCompleted
                          ? 'Completed!'
                          : isOverdue
                              ? 'Overdue by ${-daysLeft} days'
                              : '$daysLeft days left',
                      style: TextStyle(
                          fontSize: 12,
                          color: goal.isCompleted
                              ? Theme.of(context).colorScheme.primary
                              : isOverdue
                                  ? const Color(0xFFFF5252)
                                  : Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Percentage badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(goal.progress * 100).toInt()}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(
                  goal.isCompleted ? Theme.of(context).colorScheme.primary : color),
            ),
          ),
          const SizedBox(height: 10),

          // Amount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currency${goal.savedAmount.toStringAsFixed(0)} saved',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                'Target: $currency${goal.targetAmount.toStringAsFixed(0)}',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Deadline
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                'Deadline: ${_formatDate(goal.deadline)}',
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons
          if (!goal.isCompleted)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showAddMoney(context, provider, expenseProvider, goal, currency),
                    icon: Icon(Icons.add_rounded, size: 16, color: color),
                    label: Text('Add Money',
                        style: TextStyle(color: color, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => _confirmDelete(context, provider, goal),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.grey, size: 18),
                ),
              ],
            )
          else
            // Completed state
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF00C853), size: 18),
                  SizedBox(width: 6),
                  Text('Goal Achieved!',
                      style: TextStyle(
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────
  Widget _emptyState(
      BuildContext context, GoalProvider provider, String currency) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_outlined,
                  size: 40, color: Color(0xFF00C853)),
            ),
            const SizedBox(height: 20),
            const Text('No goals yet',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Set a financial goal and track your\nprogress toward achieving it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 180,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showAddGoal(context, provider, currency),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create First Goal'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add goal bottom sheet ─────────────────────────────────
  void _showAddGoal(
      BuildContext context, GoalProvider provider, String currency) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final savedCtrl = TextEditingController();
    DateTime selectedDate =
        DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Goal',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  prefixIcon: const Icon(Icons.track_changes_rounded),
                  prefixText: '$currency ',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: savedCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  labelText: 'Already Saved (optional)',
                  prefixIcon: const Icon(Icons.savings_outlined),
                  prefixText: '$currency ',
                ),
              ),
              const SizedBox(height: 14),
              // Deadline picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setSheetState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 20, color: Color(0xFF00C853)),
                      const SizedBox(width: 12),
                      Text(
                        'Deadline: ${_formatDate(selectedDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final target =
                      double.tryParse(targetCtrl.text.trim());
                  final alreadySaved =
                      double.tryParse(savedCtrl.text.trim()) ?? 0;

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a goal name'),
                          behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }
                  if (target == null || target <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid target amount'),
                          behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  provider.addGoal(Goal(
                    name: name,
                    targetAmount: target,
                    savedAmount: alreadySaved.clamp(0, target),
                    deadline: selectedDate,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add money bottom sheet ────────────────────────────────
  void _showAddMoney(BuildContext context, GoalProvider provider,
      ExpenseProvider expenseProvider, Goal goal, String currency) {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to "${goal.name}"',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Remaining: $currency${(goal.targetAmount - goal.savedAmount).toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount to Add',
                prefixIcon: const Icon(Icons.add_rounded),
                prefixText: '$currency ',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Enter a valid amount'),
                        behavior: SnackBarBehavior.floating),
                  );
                  return;
                }
                // Check balance before deducting
                final balance = expenseProvider.balance;
                if (balance <= 0) {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              color: Color(0xFFFF5252)),
                          SizedBox(width: 10),
                          Text('Balance Empty',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                      content: const Text(
                        'Your balance is empty. Add income before saving towards goals.',
                        style: TextStyle(height: 1.5),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                if (amount > balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Insufficient balance. Available: $currency${balance.toStringAsFixed(2)}'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFFFF5252),
                    ),
                  );
                  return;
                }
                provider.addMoney(goal, amount, expenseProvider);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '$currency${amount.toStringAsFixed(0)} saved for "${goal.name}" and deducted from balance'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
              child: const Text('Add Money'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation ───────────────────────────────────
  void _confirmDelete(
      BuildContext context, GoalProvider provider, Goal goal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Goal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "${goal.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteGoal(goal);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}



