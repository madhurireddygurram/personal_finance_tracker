import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart';
import '../services/user_service.dart';
import 'home.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _incomeCtrl    = TextEditingController();
  final _budgetCtrl    = TextEditingController();
  final _goalNameCtrl  = TextEditingController();
  final _goalAmountCtrl = TextEditingController();
  DateTime _goalDeadline = DateTime.now().add(const Duration(days: 90));

  bool _isStudent = false;
  int  _step      = 0;

  // 20+ currencies: display label → symbol
  static const _currencies = {
    'INR – Indian Rupee (₹)'       : '₹',
    'USD – US Dollar (\$)'          : '\$',
    'EUR – Euro (€)'                : '€',
    'GBP – British Pound (£)'       : '£',
    'JPY – Japanese Yen (¥)'        : '¥',
    'CNY – Chinese Yuan (¥)'        : '¥',
    'AUD – Australian Dollar (A\$)' : 'A\$',
    'CAD – Canadian Dollar (C\$)'   : 'C\$',
    'CHF – Swiss Franc (Fr)'        : 'Fr',
    'SGD – Singapore Dollar (S\$)'  : 'S\$',
    'AED – UAE Dirham (د.إ)'        : 'د.إ',
    'SAR – Saudi Riyal (﷼)'         : '﷼',
    'MYR – Malaysian Ringgit (RM)'  : 'RM',
    'THB – Thai Baht (฿)'           : '฿',
    'KRW – South Korean Won (₩)'    : '₩',
    'BRL – Brazilian Real (R\$)'    : 'R\$',
    'MXN – Mexican Peso (MX\$)'     : 'MX\$',
    'ZAR – South African Rand (R)'  : 'R',
    'NGN – Nigerian Naira (₦)'      : '₦',
    'IDR – Indonesian Rupiah (Rp)'  : 'Rp',
    'PKR – Pakistani Rupee (₨)'     : '₨',
    'BDT – Bangladeshi Taka (৳)'    : '৳',
    'NZD – New Zealand Dollar (NZ\$)': 'NZ\$',
    'HKD – Hong Kong Dollar (HK\$)' : 'HK\$',
  };

  String _selectedCurrency = 'INR – Indian Rupee (₹)';

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _budgetCtrl.dispose();
    _goalNameCtrl.dispose();
    _goalAmountCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF5252),
        ),
      );

  Future<void> _finish() async {
    final income = double.tryParse(_incomeCtrl.text.trim());
    final budget = double.tryParse(_budgetCtrl.text.trim());
    final label  = _isStudent ? 'pocket money' : 'income';

    if (income == null || income <= 0) {
      _snack('Please enter a valid monthly $label'); return;
    }
    if (budget == null || budget <= 0) {
      _snack('Please enter a valid monthly budget'); return;
    }
    if (budget > income) {
      _snack('Budget cannot exceed your $label'); return;
    }

    final symbol = _currencies[_selectedCurrency]!;
    final goalName   = _goalNameCtrl.text.trim();
    final goalAmount = double.tryParse(_goalAmountCtrl.text.trim()) ?? 0;

    await UserService.saveSetup(
      income   : income,
      budget   : budget,
      currency : symbol,
      goal     : goalName,
      isStudent: _isStudent,
    );

    // Auto-create the goal in the Goals tab if user filled it in
    if (goalName.isNotEmpty && goalAmount > 0 && mounted) {
      await context.read<GoalProvider>().addGoal(Goal(
        name        : goalName,
        targetAmount: goalAmount,
        savedAmount : 0,
        deadline    : _goalDeadline,
      ));
    }

    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final name = UserService.name.split(' ').first;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0FFF4), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome, $name!',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const Text('Let\'s set up your profile',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Step indicator
                    Row(
                      children: List.generate(3, (i) {
                        final done   = i < _step;
                        final active = i == _step;
                        return Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: done || active
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              if (i < 2) const SizedBox(width: 6),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == 0
                          ? 'Step 1 of 3 — Who are you?'
                          : _step == 1
                              ? 'Step 2 of 3 — Your finances'
                              : 'Step 3 of 3 — Currency & goal',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Step content ─────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _step == 0
                        ? _stepRole()
                        : _step == 1
                            ? _stepMoney()
                            : _stepCurrencyGoal(),
                  ),
                ),
              ),

              // ── Bottom buttons ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            side: const BorderSide(
                                color: Color(0xFF00C853)),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _step < 2
                            ? () => setState(() => _step++)
                            : _finish,
                        child: Text(_step < 2 ? 'Next' : 'Get Started'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Role selection ────────────────────────────────
  Widget _stepRole() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('I am a...',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('This helps us personalise your experience',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 32),
        _roleCard(
          icon: Icons.school_rounded,
          title: 'Student',
          subtitle: 'I manage pocket money / allowance',
          selected: _isStudent,
          color: const Color(0xFF7C4DFF),
          onTap: () => setState(() => _isStudent = true),
        ),
        const SizedBox(height: 16),
        _roleCard(
          icon: Icons.work_rounded,
          title: 'Working Professional',
          subtitle: 'I earn a salary / freelance income',
          selected: !_isStudent,
          color: Theme.of(context).colorScheme.primary,
          onTap: () => setState(() => _isStudent = false),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8)
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: selected ? color : Colors.black87)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                    color: selected ? color : Colors.grey.shade300,
                    width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Money ─────────────────────────────────────────
  Widget _stepMoney() {
    final incomeLabel =
        _isStudent ? 'Monthly Pocket Money' : 'Monthly Income';
    final incomeHint  =
        _isStudent ? 'e.g. 5000' : 'e.g. 50000';
    final incomeIcon  =
        _isStudent ? Icons.savings_rounded : Icons.account_balance_outlined;

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isStudent
              ? 'How much pocket money do you get?'
              : 'What is your monthly income?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text('We use this to calculate your balance automatically',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 32),
        _inputCard(
          label: incomeLabel,
          hint: incomeHint,
          icon: incomeIcon,
          controller: _incomeCtrl,
        ),
        const SizedBox(height: 20),
        _inputCard(
          label: 'Monthly Spending Budget',
          hint: _isStudent ? 'e.g. 3000' : 'e.g. 30000',
          icon: Icons.wallet_outlined,
          controller: _budgetCtrl,
          subtitle: 'We\'ll alert you when you\'re close to this limit',
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _inputCard({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Text(subtitle,
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }


  // ── Step 3: Currency + Goal ───────────────────────────────
  Widget _stepCurrencyGoal() {
    final primary = Theme.of(context).colorScheme.primary;
    return StatefulBuilder(
      builder: (_, setInner) => Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Almost done!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Choose your currency and set a financial goal',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 32),

          // Currency picker
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.currency_exchange_rounded,
                        color: primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Currency',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
                const SizedBox(height: 14),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    items: _currencies.keys
                        .map((k) => DropdownMenuItem(
                            value: k,
                            child: Text(k, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Goal card — name + amount + deadline
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flag_rounded,
                        color: Color(0xFF7C4DFF), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Financial Goal',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Optional',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('This will be added directly to your Goals tab',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                const SizedBox(height: 16),

                // Goal name
                TextField(
                  controller: _goalNameCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    hintText: 'e.g. Buy a laptop, Trip to Goa...',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // Target amount
                TextField(
                  controller: _goalAmountCtrl,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    hintText: 'e.g. 50000',
                    prefixIcon: const Icon(Icons.track_changes_rounded),
                    prefixText: '${_currencies[_selectedCurrency] ?? '₹'} ',
                  ),
                ),
                const SizedBox(height: 14),

                // Deadline picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _goalDeadline,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) setState(() => _goalDeadline = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: primary),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Target Deadline',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 11)),
                          Text(_fmtDate(_goalDeadline),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    ]),
                  ),
                ),

                // Live preview chip
                if (_goalNameCtrl.text.isNotEmpty &&
                    _goalAmountCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Color(0xFF7C4DFF), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"${_goalNameCtrl.text.trim()}" will be created in your Goals tab automatically!',
                          style: const TextStyle(
                              color: Color(0xFF7C4DFF),
                              fontSize: 12, height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

