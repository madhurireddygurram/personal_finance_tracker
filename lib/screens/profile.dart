import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/user_service.dart';
import '../services/gamification_service.dart';
import 'ai_assistant.dart';
import 'gamification.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get _darkMode => themeModeNotifier.value == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.profile,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _profileHeader(l),
          const SizedBox(height: 24),
          _section(l.settings, [
            _switchTile(Icons.dark_mode_outlined, l.darkMode, _darkMode, (v) {
              themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
              setState(() {});
            }),
            _divider(),
            _arrowTile(Icons.currency_exchange_outlined, l.currency,
                _currentCurrencyLabel.split('–').first.trim(),
                () => _showCurrencyPicker()),
            _divider(),
            _arrowTile(Icons.account_balance_wallet_outlined, 'Budget & Income',
                '${UserService.currency}${UserService.budget.toStringAsFixed(0)} / ${UserService.currency}${UserService.income.toStringAsFixed(0)}',
                _showFinancialSettings),
          ]),
          const SizedBox(height: 16),
          _section('Financial Tools & Insights', [
            _arrowTile(Icons.description_outlined, 'Financial Report & Statement', '', _exportPdf),
            _divider(),
            _arrowTile(Icons.chat_outlined, l.aiAssistant, '', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
            }),
            _divider(),
            _arrowTile(Icons.emoji_events_outlined, l.achievements,
                '${GamificationService.streak} ${l.dayStreak}',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GamificationScreen()))),
            _divider(),
            _arrowTile(Icons.group_outlined, l.splitExpenses, '', _showSplitExpenses),
          ]),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
            label: Text(l.logout,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Full currency map — label → symbol (same as setup)
  static const _currencyMap = {
    'INR – Indian Rupee (₹)'        : '₹',
    'USD – US Dollar (\$)'           : '\$',
    'EUR – Euro (€)'                 : '€',
    'GBP – British Pound (£)'        : '£',
    'JPY – Japanese Yen (¥)'         : '¥',
    'AUD – Australian Dollar (A\$)'  : 'A\$',
    'CAD – Canadian Dollar (C\$)'    : 'C\$',
    'CHF – Swiss Franc (Fr)'         : 'Fr',
    'SGD – Singapore Dollar (S\$)'   : 'S\$',
    'AED – UAE Dirham (د.إ)'         : 'د.إ',
    'SAR – Saudi Riyal (﷼)'          : '﷼',
    'MYR – Malaysian Ringgit (RM)'   : 'RM',
    'THB – Thai Baht (฿)'            : '฿',
    'KRW – South Korean Won (₩)'     : '₩',
    'CNY – Chinese Yuan (¥)'         : '¥',
    'BRL – Brazilian Real (R\$)'     : 'R\$',
    'MXN – Mexican Peso (MX\$)'      : 'MX\$',
    'ZAR – South African Rand (R)'   : 'R',
    'NGN – Nigerian Naira (₦)'       : '₦',
    'IDR – Indonesian Rupiah (Rp)'   : 'Rp',
    'PKR – Pakistani Rupee (₨)'      : '₨',
    'BDT – Bangladeshi Taka (৳)'     : '৳',
    'NZD – New Zealand Dollar (NZ\$)': 'NZ\$',
    'HKD – Hong Kong Dollar (HK\$)'  : 'HK\$',
  };

  // Find the display label for the currently saved symbol
  String get _currentCurrencyLabel {
    final sym = UserService.currency;
    return _currencyMap.entries
        .firstWhere((e) => e.value == sym,
            orElse: () => _currencyMap.entries.first)
        .key;
  }

  // ── Profile header — real name & email ────────────────────
  Widget _profileHeader(AppLocalizations l) {
    final name = UserService.name;
    final email = UserService.email;
    final initial = UserService.initial;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C853)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(email,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(l.activeMember,
                      style: TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _showEditProfile,
          ),
        ],
      ),
    );
  }

  // ── Section container ─────────────────────────────────────
  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade500,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _divider() => Divider(
      height: 1, indent: 56, endIndent: 16, color: Colors.grey.shade100);

  // ── Actions ───────────────────────────────────────────────
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showEditProfile() {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: UserService.name);
    final emailCtrl = TextEditingController(text: UserService.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.editProfile,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                  labelText: l.fullName,
                  prefixIcon: const Icon(Icons.person_outline_rounded)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  labelText: l.email,
                  prefixIcon: const Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                if (name.isEmpty || email.isEmpty) {
                  _snack(l.fieldsEmpty);
                  return;
                }
                await UserService.updateProfile(name: name, email: email);
                if (!mounted || !sheetCtx.mounted) return;
                Navigator.pop(sheetCtx);
                setState(() {});
                _snack(l.profileUpdated);
              },
              child: Text(l.saveChanges),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinancialSettings() {
    final currency = UserService.currency;
    final incomeCtrl = TextEditingController(
        text: UserService.income > 0 ? UserService.income.toStringAsFixed(0) : '');
    final budgetCtrl = TextEditingController(
        text: UserService.budget > 0 ? UserService.budget.toStringAsFixed(0) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financial Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Adjust your base monthly income and monthly spending limit.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: incomeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly Income',
                prefixText: '$currency ',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: budgetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly Budget Limit',
                prefixText: '$currency ',
                prefixIcon: const Icon(Icons.pie_chart_outline_rounded),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final inc = double.tryParse(incomeCtrl.text.trim()) ?? 0.0;
                final bud = double.tryParse(budgetCtrl.text.trim()) ?? 0.0;
                if (inc <= 0) {
                  _snack('Please enter a valid monthly income');
                  return;
                }
                if (bud <= 0) {
                  _snack('Please enter a valid monthly budget');
                  return;
                }
                await UserService.saveSetup(
                  income: inc,
                  budget: bud,
                  currency: UserService.currency,
                  goal: UserService.goal,
                  isStudent: UserService.isStudent,
                );
                if (!mounted || !sheetCtx.mounted) return;
                context.read<ExpenseProvider>().loadExpenses();
                Navigator.pop(sheetCtx);
                setState(() {});
                _snack('Financial settings updated successfully!');
              },
              child: const Text('Save Financial Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportPdf() {
    final l = AppLocalizations.of(context);
    final currency = UserService.currency;
    final ep = context.read<ExpenseProvider>();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.exportReport, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exportOption(Icons.calendar_view_month_rounded, l.thisMonth, () {
              Navigator.pop(dlgCtx);
              _showReportModal('This Month', DateTime.now().subtract(const Duration(days: 30)), ep, currency);
            }),
            _exportOption(Icons.date_range_rounded, l.last3Months, () {
              Navigator.pop(dlgCtx);
              _showReportModal('Last 3 Months', DateTime.now().subtract(const Duration(days: 90)), ep, currency);
            }),
            _exportOption(Icons.calendar_today_rounded, l.thisYear, () {
              Navigator.pop(dlgCtx);
              _showReportModal('This Year', DateTime(DateTime.now().year, 1, 1), ep, currency);
            }),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: Text(l.cancel)),
        ],
      ),
    );
  }

  Widget _exportOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      onTap: onTap,
    );
  }

  void _showReportModal(String periodName, DateTime since, ExpenseProvider ep, String currency) {
    final filtered = ep.expenses.where((e) => e.date.isAfter(since)).toList();
    final expenses = filtered.where((e) => e.isExpense).toList();
    final incomes = filtered.where((e) => !e.isExpense).toList();

    final totalSpent = expenses.fold(0.0, (s, e) => s + e.amount);
    final extraIncome = incomes.fold(0.0, (s, e) => s + e.amount);
    final totalIncome = UserService.income + extraIncome;
    final netSavings = totalIncome - totalSpent;

    final catTotals = <String, double>{};
    for (final e in expenses) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }

    final reportText = StringBuffer();
    reportText.writeln('=== Finance AI Report ($periodName) ===');
    reportText.writeln('User: ${UserService.name}');
    reportText.writeln('Total Income: $currency${totalIncome.toStringAsFixed(0)}');
    reportText.writeln('Total Expenses: $currency${totalSpent.toStringAsFixed(0)}');
    reportText.writeln('Net Savings: $currency${netSavings.toStringAsFixed(0)}');
    reportText.writeln('\nCategory Breakdown:');
    catTotals.forEach((k, v) => reportText.writeln('• $k: $currency${v.toStringAsFixed(0)}'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Financial Summary: $periodName',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Income', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('$currency${totalIncome.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00C853))),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Expenses', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('$currency${totalSpent.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF5252))),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Net Savings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('$currency${netSavings.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00897B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Top Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            if (catTotals.isEmpty)
              const Text('No expenses recorded for this period', style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              ...catTotals.entries.take(4).map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 13)),
                        Text('$currency${entry.value.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  )),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reportText.toString()));
                Navigator.pop(ctx);
                _snack('Financial summary copied to clipboard!');
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Summary Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSplitExpenses() {
    final l = AppLocalizations.of(context);
    final currency = UserService.currency;
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final peopleCtrl = TextEditingController(text: '2');
    double share = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void updateShare() {
            final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
            final numPeople = int.tryParse(peopleCtrl.text.trim()) ?? 1;
            setSheetState(() {
              share = (numPeople > 0) ? (amt / numPeople) : 0.0;
            });
          }

          return Padding(
            padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l.splitExpenses,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(sheetCtx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: l.expenseName,
                      prefixIcon: const Icon(Icons.receipt_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => updateShare(),
                    decoration: InputDecoration(
                      labelText: l.amount,
                      prefixText: '$currency ',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: peopleCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => updateShare(),
                    decoration: InputDecoration(
                      labelText: l.numPeople,
                      prefixIcon: const Icon(Icons.group_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (share > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Each Person Pays:',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('$currency${share.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final title = nameCtrl.text.trim().isEmpty ? 'Split Expense' : nameCtrl.text.trim();
                      if (share <= 0) {
                        _snack('Please enter valid amount and number of people');
                        return;
                      }
                      // Record user's portion into ExpenseProvider
                      await context.read<ExpenseProvider>().addExpense(Expense(
                        amount: share,
                        category: 'Other',
                        note: '$title (My share of $currency${amountCtrl.text.trim()})',
                        date: DateTime.now(),
                        isExpense: true,
                      ));
                      if (!mounted || !sheetCtx.mounted) return;
                      Navigator.pop(sheetCtx);
                      _snack('My share of $currency${share.toStringAsFixed(2)} added to expenses!');
                    },
                    child: Text(share > 0 ? 'Record My Share ($currency${share.toStringAsFixed(2)})' : l.splitShare),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCurrencyPicker() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 16),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(alignment: Alignment.centerLeft,
                  child: Text(l.selectCurrency,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: _currencyMap.entries.map((entry) {
                  final isSelected = UserService.currency == entry.value;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(entry.value,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade600)),
                      ),
                    ),
                    title: Text(entry.key.split('–').last.trim(),
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(entry.key.split('–').first.trim(),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00C853))
                        : null,
                    onTap: () async {
                      await UserService.saveSetup(
                        income  : UserService.income,
                        budget  : UserService.budget,
                        currency: entry.value,
                        goal    : UserService.goal,
                      );
                      if (!mounted) return;
                      setState(() {});
                      Navigator.pop(context);
                      _snack('${l.currChanged} ${entry.value}');
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.logout,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              await UserService.logout();
              themeModeNotifier.value = ThemeMode.light;
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: Text(l.logout),
          ),
        ],
      ),
    );
  }

  // ── Tile widgets ──────────────────────────────────────────
  Widget _switchTile(IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: primary,
      ),
    );
  }

  Widget _arrowTile(IconData icon, String label, String subtitle,
      VoidCallback onTap) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

