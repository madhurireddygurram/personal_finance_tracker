import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/user_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();

  String   _selectedCat  = 'Food';
  bool     _isExpense    = true;
  DateTime _selectedDate = DateTime.now();
  bool     _autoDetected = false; // shows badge when category was auto-set

  // ── Category definitions ──────────────────────────────────
  static const _cats = [
    {'label': 'Food',          'icon': Icons.restaurant_rounded,      'color': 0xFF00C853},
    {'label': 'Transport',     'icon': Icons.directions_car_rounded,   'color': 0xFF7C4DFF},
    {'label': 'Shopping',      'icon': Icons.shopping_bag_rounded,     'color': 0xFFFF6D00},
    {'label': 'Bills',         'icon': Icons.receipt_long_rounded,     'color': 0xFFFF5252},
    {'label': 'Health',        'icon': Icons.favorite_rounded,         'color': 0xFF00BCD4},
    {'label': 'Education',     'icon': Icons.school_rounded,           'color': 0xFF3D5AFE},
    {'label': 'Entertainment', 'icon': Icons.movie_rounded,            'color': 0xFFFF4081},
    {'label': 'Other',         'icon': Icons.category_rounded,         'color': 0xFF9E9E9E},
  ];

  // ── Keyword → category map ────────────────────────────────
  static const _keywords = <String, String>{
    // Food
    'swiggy':'Food','zomato':'Food','dominos':'Food','pizza':'Food',
    'burger':'Food','mcdonalds':'Food','kfc':'Food','subway':'Food',
    'restaurant':'Food','cafe':'Food','coffee':'Food','tea':'Food',
    'lunch':'Food','dinner':'Food','breakfast':'Food','snack':'Food',
    'grocery':'Food','vegetables':'Food','fruits':'Food','milk':'Food',
    'hotel':'Food','biryani':'Food','food':'Food',
    // Transport
    'uber':'Transport','ola':'Transport','rapido':'Transport',
    'bus':'Transport','metro':'Transport','train':'Transport',
    'auto':'Transport','taxi':'Transport','petrol':'Transport',
    'fuel':'Transport','diesel':'Transport','parking':'Transport',
    'flight':'Transport','cab':'Transport','transport':'Transport',
    // Shopping
    'amazon':'Shopping','flipkart':'Shopping','myntra':'Shopping',
    'ajio':'Shopping','clothes':'Shopping','shirt':'Shopping',
    'shoes':'Shopping','dress':'Shopping','shopping':'Shopping',
    'mall':'Shopping','market':'Shopping','purchase':'Shopping',
    // Bills
    'electricity':'Bills','water':'Bills','internet':'Bills',
    'wifi':'Bills','mobile':'Bills','recharge':'Bills',
    'netflix':'Bills','spotify':'Bills','hotstar':'Bills',
    'subscription':'Bills','rent':'Bills','emi':'Bills',
    'insurance':'Bills','bill':'Bills','utility':'Bills',
    // Health
    'medicine':'Health','doctor':'Health','hospital':'Health',
    'pharmacy':'Health','clinic':'Health','gym':'Health',
    'health':'Health','medical':'Health','tablet':'Health',
    // Education
    'book':'Education','course':'Education','tuition':'Education',
    'college':'Education','school':'Education','fees':'Education',
    'exam':'Education','stationery':'Education','pen':'Education',
    'notebook':'Education','education':'Education',
    // Entertainment
    'movie':'Entertainment','cinema':'Entertainment','game':'Entertainment',
    'concert':'Entertainment','party':'Entertainment','outing':'Entertainment',
    'trip':'Entertainment','travel':'Entertainment','fun':'Entertainment',
  };

  // Auto-detect category from note text
  String _detectCategory(String note) {
    final lower = note.toLowerCase();
    for (final entry in _keywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'Other';
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    // Listen to note changes and auto-detect category
    _noteCtrl.addListener(() {
      if (_isExpense && _noteCtrl.text.trim().isNotEmpty) {
        final detected = _detectCategory(_noteCtrl.text);
        if (detected != _selectedCat) {
          setState(() {
            _selectedCat  = detected;
            _autoDetected = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Please enter a valid amount', error: true);
      return;
    }

    final provider = context.read<ExpenseProvider>();

    // Block expense if balance is zero or insufficient
    if (_isExpense) {
      final balance = provider.balance;
      if (balance <= 0) {
        _showEmptyBalanceDialog();
        return;
      }
      if (amount > balance) {
        _showInsufficientBalanceDialog(balance);
        return;
      }
    }

    final expense = Expense(
      amount   : amount,
      category : _isExpense ? _selectedCat : 'Income',
      note     : _noteCtrl.text.trim(),
      date     : _selectedDate,
      isExpense: _isExpense,
    );
    await provider.addExpense(expense);
    if (!mounted) return;
    _snack(
      '${_isExpense ? "Expense" : "Income"} of ${UserService.currency}$amount saved!',
      error: false,
    );
    Navigator.pop(context);
  }

  void _showEmptyBalanceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: Color(0xFFFF5252)),
            SizedBox(width: 10),
            Text('Balance Empty',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Your balance is empty. You cannot add more expenses.\n\nAdd income first to continue tracking expenses.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch to income mode
              setState(() {
                _isExpense = false;
                _amountCtrl.clear();
              });
            },
            child: const Text('Add Income Instead'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientBalanceDialog(double balance) {
    final currency = UserService.currency;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6D00)),
            SizedBox(width: 10),
            Text('Insufficient Balance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'You only have $currency${balance.toStringAsFixed(2)} available.\nYou cannot spend more than your current balance.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {required bool error}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? const Color(0xFFFF5252) : Theme.of(context).colorScheme.primary,
      ));

  @override
  Widget build(BuildContext context) {
    final currency = UserService.currency;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Add Transaction',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10)
                ],
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.edit_rounded, size: 16), text: 'Manual'),
                  Tab(icon: Icon(Icons.mic_rounded, size: 16), text: 'Voice'),
                  Tab(icon: Icon(Icons.camera_alt_rounded, size: 16), text: 'Scan'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _manualTab(currency),
                _voiceTab(),
                _scanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Manual Tab ────────────────────────────────────────────
  Widget _manualTab(String currency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expense / Income toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10)
              ],
            ),
            child: Row(
              children: [
                _toggleBtn('Expense', true,
                    const Color(0xFFFF5252), Icons.arrow_upward_rounded),
                _toggleBtn('Income', false,
                    Theme.of(context).colorScheme.primary, Icons.arrow_downward_rounded),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount + note card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(currency,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _isExpense
                                ? const Color(0xFFFF5252)
                                : Theme.of(context).colorScheme.primary)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _isExpense
                                ? const Color(0xFFFF5252)
                                : Theme.of(context).colorScheme.primary),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade200,
                              fontSize: 36,
                              fontWeight: FontWeight.bold),
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade100, height: 24),
                Text('Note',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Swiggy, Uber, Netflix...',
                          hintStyle:
                              TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_autoDetected && _isExpense)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 12, color: Color(0xFF00C853)),
                            const SizedBox(width: 4),
                            Text('Auto',
                                style: const TextStyle(
                                    color: Color(0xFF00C853),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category (only for expenses)
          if (_isExpense) ...[
            Row(
              children: [
                const Text('Category',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                if (_autoDetected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Auto-detected',
                        style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _cats.map((cat) {
                final label  = cat['label'] as String;
                final icon   = cat['icon'] as IconData;
                final color  = Color(cat['color'] as int);
                final active = _selectedCat == label;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCat  = label;
                    _autoDetected = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? color : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: active ? color : Colors.grey.shade200),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 16,
                            color: active ? Colors.white : color),
                        const SizedBox(width: 6),
                        Text(label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : Colors.grey.shade700)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Date picker
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
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
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded,
                        size: 18, color: Color(0xFF00C853)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11)),
                      Text(_formatDate(_selectedDate),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isExpense
                    ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                    : [Theme.of(context).colorScheme.primary, const Color(0xFF00897B)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: (_isExpense
                            ? const Color(0xFFFF5252)
                            : Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                  _isExpense ? 'Save Expense' : 'Save Income',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(
      String label, bool isExp, Color color, IconData icon) {
    final active = _isExpense == isExp;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _isExpense    = isExp;
          _autoDetected = false;
          if (!isExp) _selectedCat = 'Food';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date  = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Voice Tab ─────────────────────────────────────────────
  Widget _voiceTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00897B)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.mic_rounded,
                  size: 60, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text('Tap to speak',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Say something like:',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 16),
            _voiceExample('"Spent 200 on Swiggy"'),
            const SizedBox(height: 8),
            _voiceExample('"Uber ride 150 rupees"'),
            const SizedBox(height: 8),
            _voiceExample('"Netflix subscription 649"'),
          ],
        ),
      ),
    );
  }

  Widget _voiceExample(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.record_voice_over_rounded,
              size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Scan Tab ──────────────────────────────────────────────
  Widget _scanTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16)
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 48, color: Color(0xFF00C853)),
                  ),
                  const SizedBox(height: 12),
                  Text('Scan Bill / Receipt',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Auto-extracts amount & date',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Point your camera at any bill or receipt',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Open Camera'),
            ),
          ],
        ),
      ),
    );
  }
}

