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
        final primary = Theme.of(context).colorScheme.primary;
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          _showAddGoal(context, provider, currency),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Goal'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                    ? _emptyState(context, provider, currency, primary)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.goals.length,
                        itemBuilder: (_, i) => _goalCard(
                          context,
                          provider,
                          expenseProvider,
                          provider.goals[i],
                          _colorFor(i),
                          currency,
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
  Widget _summaryBar(
    GoalProvider provider,
    ExpenseProvider ep,
    String currency,
  ) {
    final saved = provider.goals.fold(0.0, (s, g) => s + g.savedAmount);
    final completed = provider.goals.where((g) => g.isCompleted).length;
    final deducted = ep.totalGoalSavings;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00C853).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00C853).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(
            'Total',
            '${provider.goals.length}',
            Icons.flag_rounded,
            const Color(0xFF00C853),
          ),
          _vDivider(),
          _summaryItem(
            'Saved',
            '$currency${saved.toStringAsFixed(0)}',
            Icons.savings_outlined,
            const Color(0xFF7C4DFF),
          ),
          _vDivider(),
          _summaryItem(
            'Deducted',
            '-$currency${deducted.toStringAsFixed(0)}',
            Icons.account_balance_wallet_outlined,
            const Color(0xFFFF5252),
          ),
          _vDivider(),
          _summaryItem(
            'Done',
            '$completed',
            Icons.check_circle_outline_rounded,
            const Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.shade200);

  // ── Goal card ─────────────────────────────────────────────
  Widget _goalCard(
    BuildContext context,
    GoalProvider provider,
    ExpenseProvider expenseProvider,
    Goal goal,
    Color color,
    String currency,
  ) {
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0 && !goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
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
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.flag_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      goal.isCompleted
                          ? 'Completed!'
                          : isOverdue
                          ? 'Overdue by ${-daysLeft} days'
                          : '$daysLeft days left',
                      style: TextStyle(
                        fontSize: 12,
                        color: goal.isCompleted
                            ? color
                            : isOverdue
                            ? const Color(0xFFFF5252)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(goal.progress * 100).toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),

          // Amount + deadline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currency${goal.savedAmount.toStringAsFixed(0)} saved',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Target: $currency${goal.targetAmount.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                'Deadline: ${_formatDate(goal.deadline)}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          if (!goal.isCompleted) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.savings_outlined, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  () {
                    final daysRemaining = goal.deadline
                        .difference(DateTime.now())
                        .inDays;
                    final remaining = goal.targetAmount - goal.savedAmount;
                    if (daysRemaining <= 0) return 'Deadline passed';
                    final daily = remaining / daysRemaining;
                    return 'Save $currency${daily.toStringAsFixed(2)}/day to reach goal';
                  }(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // ── 3 Action buttons ──────────────────────────────
          if (!goal.isCompleted)
            Row(
              children: [
                // Add Savings
                Expanded(
                  child: _actionBtn(
                    icon: Icons.savings_rounded,
                    label: 'Add Savings',
                    color: color,
                    filled: true,
                    onTap: () => _showAddMoney(
                      context,
                      provider,
                      expenseProvider,
                      goal,
                      currency,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit
                Expanded(
                  child: _actionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: const Color(0xFF7C4DFF),
                    filled: false,
                    onTap: () =>
                        _showEditGoal(context, provider, goal, currency),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete
                Expanded(
                  child: _actionBtn(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: const Color(0xFFFF5252),
                    filled: false,
                    onTap: () => _confirmDelete(context, provider, goal),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Goal Achieved!',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: filled
              ? null
              : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────
  Widget _emptyState(
    BuildContext context,
    GoalProvider provider,
    String currency,
    Color primary,
  ) {
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
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flag_outlined, size: 40, color: primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No goals yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Set a financial goal and track your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () => _showAddGoal(context, provider, currency),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Create First Goal',
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add goal ──────────────────────────────────────────────
  void _showAddGoal(
    BuildContext context,
    GoalProvider provider,
    String currency,
  ) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final savedCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _goalSheet(
          ctx: ctx,
          title: 'New Goal',
          nameCtrl: nameCtrl,
          targetCtrl: targetCtrl,
          savedCtrl: savedCtrl,
          selectedDate: selectedDate,
          currency: currency,
          onDatePick: (d) => setSheet(() => selectedDate = d),
          onSave: () {
            final name = nameCtrl.text.trim();
            final target = double.tryParse(targetCtrl.text.trim());
            final already = double.tryParse(savedCtrl.text.trim()) ?? 0;
            if (name.isEmpty) {
              _snack(context, 'Enter a goal name');
              return;
            }
            if (target == null || target <= 0) {
              _snack(context, 'Enter a valid target');
              return;
            }
            provider.addGoal(
              Goal(
                name: name,
                targetAmount: target,
                savedAmount: already.clamp(0, target),
                deadline: selectedDate,
              ),
            );
            Navigator.pop(ctx);
          },
          btnLabel: 'Create Goal',
        ),
      ),
    );
  }

  // ── Edit goal ─────────────────────────────────────────────
  void _showEditGoal(
    BuildContext context,
    GoalProvider provider,
    Goal goal,
    String currency,
  ) {
    final nameCtrl = TextEditingController(text: goal.name);
    final targetCtrl = TextEditingController(
      text: goal.targetAmount.toStringAsFixed(0),
    );
    final savedCtrl = TextEditingController(
      text: goal.savedAmount.toStringAsFixed(0),
    );
    DateTime selectedDate = goal.deadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _goalSheet(
          ctx: ctx,
          title: 'Edit Goal',
          nameCtrl: nameCtrl,
          targetCtrl: targetCtrl,
          savedCtrl: savedCtrl,
          selectedDate: selectedDate,
          currency: currency,
          onDatePick: (d) => setSheet(() => selectedDate = d),
          onSave: () async {
            final name = nameCtrl.text.trim();
            final target = double.tryParse(targetCtrl.text.trim());
            final saved =
                double.tryParse(savedCtrl.text.trim()) ?? goal.savedAmount;
            if (name.isEmpty) {
              _snack(context, 'Enter a goal name');
              return;
            }
            if (target == null || target <= 0) {
              _snack(context, 'Enter a valid target');
              return;
            }
            goal.name = name;
            goal.targetAmount = target;
            goal.savedAmount = saved.clamp(0, target);
            goal.deadline = selectedDate;
            await provider.updateGoal(goal);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          btnLabel: 'Save Changes',
        ),
      ),
    );
  }

  // ── Shared goal bottom sheet ──────────────────────────────
  Widget _goalSheet({
    required BuildContext ctx,
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController targetCtrl,
    required TextEditingController savedCtrl,
    required DateTime selectedDate,
    required String currency,
    required ValueChanged<DateTime> onDatePick,
    required VoidCallback onSave,
    required String btnLabel,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                decimal: true,
              ),
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
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Already Saved (optional)',
                prefixIcon: const Icon(Icons.savings_outlined),
                prefixText: '$currency ',
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) onDatePick(picked);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Deadline: ${_formatDate(selectedDate)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onSave, child: Text(btnLabel)),
          ],
        ),
      ),
    );
  }

  // ── Add money ─────────────────────────────────────────────
  void _showAddMoney(
    BuildContext context,
    GoalProvider provider,
    ExpenseProvider expenseProvider,
    Goal goal,
    String currency,
  ) {
    final amountCtrl = TextEditingController();
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
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Savings to "${goal.name}"',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Remaining: $currency${(goal.targetAmount - goal.savedAmount).toStringAsFixed(0)}  •  Balance: $currency${expenseProvider.balance.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: const Icon(Icons.savings_rounded),
                prefixText: '$currency ',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) {
                  _snack(context, 'Enter a valid amount');
                  return;
                }
                final balance = expenseProvider.balance;
                if (balance <= 0) {
                  Navigator.pop(ctx);
                  _showEmptyBalanceDialog(context);
                  return;
                }
                if (amount > balance) {
                  _snack(
                    context,
                    'Insufficient balance. Available: $currency${balance.toStringAsFixed(2)}',
                  );
                  return;
                }
                provider.addMoney(goal, amount, expenseProvider);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$currency${amount.toStringAsFixed(0)} saved for "${goal.name}"',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
              child: const Text('Add Savings'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmptyBalanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Color(0xFFFF5252),
            ),
            SizedBox(width: 10),
            Text(
              'Balance Empty',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Your balance is empty. Add income before saving towards goals.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, GoalProvider provider, Goal goal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Goal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Delete "${goal.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF5252),
        ),
      );

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
