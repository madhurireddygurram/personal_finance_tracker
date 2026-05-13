import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _incomeCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _goalCtrl   = TextEditingController();

  bool _isStudent = false;
  int  _step      = 0; // 0 = role, 1 = money, 2 = currency+goal

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
    _goalCtrl.dispose();
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
      _snack('Please enter a valid monthly $label');
      return;
    }
    if (budget == null || budget <= 0) {
      _snack('Please enter a valid monthly budget');
      return;
    }
    if (budget > income) {
      _snack('Budget cannot exceed your $label');
      return;
    }

    await UserService.saveSetup(
      income   : income,
      budget   : budget,
      currency : _currencies[_selectedCurrency]!,
      goal     : _goalCtrl.text.trim(),
      isStudent: _isStudent,
    );

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
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Almost done!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Choose your currency and set an optional goal',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 32),

        // Currency picker
        Container(
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
                    child: const Icon(Icons.currency_exchange_rounded,
                        color: Color(0xFF00C853), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Currency',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCurrency,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF00C853)),
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87),
                  items: _currencies.keys
                      .map((k) => DropdownMenuItem(
                          value: k,
                          child: Text(k,
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCurrency = v!),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Goal (optional)
        Container(
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
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flag_rounded,
                        color: Color(0xFF7C4DFF), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Financial Goal',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Optional',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _goalCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Buy a laptop, Trip to Goa...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

