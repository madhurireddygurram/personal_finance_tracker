import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../services/user_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _search = '';
  String _filter = 'All';
  final _filters = [
    'All','Food','Transport','Shopping',
    'Bills','Health','Education','Entertainment','Income'
  ];

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

  static const _catColors = <String, Color>{
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

  static const _editableCategories = [
    'Food','Transport','Shopping','Bills',
    'Health','Education','Entertainment','Other',
  ];

  // ── Edit bottom sheet ─────────────────────────────────────
  void _showEdit(BuildContext context, Expense e, ExpenseProvider provider) {
    final amountCtrl = TextEditingController(
        text: e.amount.toStringAsFixed(e.amount % 1 == 0 ? 0 : 2));
    final noteCtrl   = TextEditingController(text: e.note);
    String selCat    = e.isExpense ? e.category : 'Income';
    bool   isExpense = e.isExpense;
    DateTime selDate = e.date;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Transaction',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red),
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.deleteExpense(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction deleted'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Expense / Income toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _sheetToggle('Expense', true, isExpense,
                          const Color(0xFFFF5252), () {
                        setSheet(() => isExpense = true);
                      }),
                      _sheetToggle('Income', false, isExpense,
                          Theme.of(context).colorScheme.primary, () {
                        setSheet(() {
                          isExpense = false;
                          selCat    = 'Income';
                        });
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(UserService.currency,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isExpense
                                  ? const Color(0xFFFF5252)
                                  : Theme.of(context).colorScheme.primary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            hintText: '0.00',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Note
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      border: InputBorder.none,
                      filled: false,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category chips (only for expenses)
                if (isExpense) ...[
                  const Text('Category',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _editableCategories.map((cat) {
                      final active = selCat == cat;
                      final color  = _catColors[cat] ?? Colors.grey;
                      final icon   = _catIcons[cat] ?? Icons.category_rounded;
                      return GestureDetector(
                        onTap: () => setSheet(() => selCat = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? color : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: active
                                    ? color
                                    : Colors.grey.shade200),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                        color: color.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2))
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon,
                                  size: 14,
                                  color: active
                                      ? Colors.white
                                      : color),
                              const SizedBox(width: 5),
                              Text(cat,
                                  style: TextStyle(
                                      fontSize: 12,
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
                  const SizedBox(height: 12),
                ],

                // Date
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setSheet(() => selDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: Color(0xFF00C853)),
                        const SizedBox(width: 10),
                        Text(_fmtDate(selDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a valid amount'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    e.amount    = amount;
                    e.note      = noteCtrl.text.trim();
                    e.category  = isExpense ? selCat : 'Income';
                    e.isExpense = isExpense;
                    e.date      = selDate;
                    await provider.updateExpense(e);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetToggle(String label, bool isExp, bool currentIsExp,
      Color color, VoidCallback onTap) {
    final active = currentIsExp == isExp;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: active ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date  = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currency = UserService.currency;
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final filtered = provider.expenses.where((e) {
          final matchSearch = _search.isEmpty ||
              e.note.toLowerCase().contains(_search.toLowerCase()) ||
              e.category.toLowerCase().contains(_search.toLowerCase());
          final matchFilter = _filter == 'All' || e.category == _filter;
          return matchSearch && matchFilter;
        }).toList();

        final grouped = _group(filtered);

        return SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transactions',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${filtered.length} records',
                              style: const TextStyle(
                                  color: Color(0xFF00C853),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final active = _filter == _filters[i];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _filter = _filters[i]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: active
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                            color: Theme.of(context).colorScheme.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2))
                                      ]
                                    : [],
                              ),
                              child: Text(_filters[i],
                                  style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : Colors.grey,
                                      fontWeight: active
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 13)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: grouped.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: grouped.length,
                        itemBuilder: (_, i) {
                          final entry = grouped.entries.elementAt(i);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key,
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    Text(
                                      _groupTotal(
                                          entry.value, currency),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFF5252),
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              ...entry.value.map((e) =>
                                  _txnTile(e, provider, currency)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<Expense>> _group(List<Expense> list) {
    final Map<String, List<Expense>> grouped = {};
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    const months    = ['Jan','Feb','Mar','Apr','May','Jun',
                       'Jul','Aug','Sep','Oct','Nov','Dec'];
    for (final e in list) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      String label;
      if (d == today)         label = 'Today';
      else if (d == yesterday) label = 'Yesterday';
      else                     label = '${e.date.day} ${months[e.date.month - 1]}';
      grouped.putIfAbsent(label, () => []).add(e);
    }
    return grouped;
  }

  String _groupTotal(List<Expense> items, String currency) {
    final total = items
        .where((e) => e.isExpense)
        .fold(0.0, (sum, e) => sum + e.amount);
    return total > 0 ? '-$currency${total.toStringAsFixed(0)}' : '';
  }

  Widget _txnTile(
      Expense e, ExpenseProvider provider, String currency) {
    final color = _catColors[e.category] ?? Colors.grey;
    final icon  = _catIcons[e.category] ?? Icons.category_rounded;

    return Dismissible(
      key: Key('${e.key}_${e.amount}'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.red),
            const SizedBox(height: 2),
            Text('Delete',
                style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        provider.deleteExpense(e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: GestureDetector(
        // Tap to edit
        onTap: () => _showEdit(context, e, provider),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.note.isEmpty ? e.category : e.note,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(e.category,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Text(_fmtDate(e.date),
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${e.isExpense ? '-' : '+'}$currency${e.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: e.isExpense
                            ? const Color(0xFFFF5252)
                            : Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 2),
                  Icon(Icons.edit_outlined,
                      size: 12, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 36, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text('No transactions found',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            _search.isNotEmpty || _filter != 'All'
                ? 'Try changing your search or filter'
                : 'Tap + to add your first transaction',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}



