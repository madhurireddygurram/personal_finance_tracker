import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/user_service.dart';
import '../services/voice_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final int initialTab;
  const AddExpenseScreen({super.key, this.initialTab = 0});
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
  bool     _autoDetected = false;

  // Voice state
  bool   _isListening    = false;
  bool   _voiceReady     = false;
  String _voiceTranscript = '';
  String _voiceStatus    = 'Tap the mic to start';

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

  static const _keywords = <String, String>{
    'swiggy':'Food','zomato':'Food','dominos':'Food','pizza':'Food',
    'burger':'Food','mcdonalds':'Food','kfc':'Food','restaurant':'Food',
    'cafe':'Food','coffee':'Food','lunch':'Food','dinner':'Food',
    'breakfast':'Food','grocery':'Food','milk':'Food','food':'Food',
    'uber':'Transport','ola':'Transport','rapido':'Transport',
    'bus':'Transport','metro':'Transport','train':'Transport',
    'auto':'Transport','taxi':'Transport','petrol':'Transport',
    'fuel':'Transport','cab':'Transport','transport':'Transport',
    'amazon':'Shopping','flipkart':'Shopping','myntra':'Shopping',
    'clothes':'Shopping','shoes':'Shopping','shopping':'Shopping',
    'electricity':'Bills','water':'Bills','internet':'Bills',
    'wifi':'Bills','netflix':'Bills','spotify':'Bills',
    'subscription':'Bills','rent':'Bills','emi':'Bills','bill':'Bills',
    'medicine':'Health','doctor':'Health','hospital':'Health',
    'pharmacy':'Health','gym':'Health','health':'Health',
    'book':'Education','course':'Education','tuition':'Education',
    'fees':'Education','education':'Education',
    'movie':'Entertainment','cinema':'Entertainment','game':'Entertainment',
    'party':'Entertainment','entertainment':'Entertainment',
  };

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
    _tab = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _initVoice();
    _noteCtrl.addListener(() {
      if (_isExpense && _noteCtrl.text.trim().isNotEmpty) {
        final detected = _detectCategory(_noteCtrl.text);
        if (detected != _selectedCat) {
          setState(() { _selectedCat = detected; _autoDetected = true; });
        }
      }
    });
  }

  Future<void> _initVoice() async {
    final ok = await VoiceService.initialize();
    if (mounted) setState(() => _voiceReady = ok);
  }

  Future<void> _startListening() async {
    if (!_voiceReady || _isListening) return;
    setState(() {
      _isListening = true;
      _voiceTranscript = '';
      _voiceStatus = 'Listening...';
    });
    await VoiceService.listen(
      onResult: (text) {
        if (mounted) setState(() => _voiceTranscript = text);
      },
      onDone: () {
        if (!mounted) return;
        final result = VoiceService.parse(_voiceTranscript);
        setState(() {
          _isListening = false;
          _voiceStatus = _voiceTranscript.isEmpty
              ? 'Nothing heard. Try again.'
              : 'Got it! Review below.';
          if (result.amount != null) {
            _amountCtrl.text = result.amount!.toStringAsFixed(2);
          }
          if (_voiceTranscript.isNotEmpty) {
            _noteCtrl.text = result.note;
            _selectedCat   = result.category;
            _autoDetected  = true;
          }
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await VoiceService.stop();
    if (mounted) setState(() { _isListening = false; _voiceStatus = 'Tap the mic to start'; });
  }

  @override
  void dispose() {
    VoiceService.stop();
    _tab.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Please enter a valid amount', error: true); return;
    }
    final provider = context.read<ExpenseProvider>();
    if (_isExpense) {
      final balance = provider.balance;
      if (balance <= 0) { _showEmptyBalanceDialog(); return; }
      if (amount > balance) { _showInsufficientDialog(balance); return; }
    }
    await provider.addExpense(Expense(
      amount: amount, category: _isExpense ? _selectedCat : 'Income',
      note: _noteCtrl.text.trim(), date: _selectedDate, isExpense: _isExpense,
    ));
    if (!mounted) return;
    _snack('${_isExpense ? "Expense" : "Income"} of ${UserService.currency}$amount saved!',
        error: false);
    Navigator.pop(context);
  }

  void _snack(String msg, {required bool error}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFFF5252)
            : Theme.of(context).colorScheme.primary,
      ));

  void _showEmptyBalanceDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFFF5252)),
        SizedBox(width: 10),
        Text('Balance Empty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ]),
      content: const Text('Your balance is empty. Add income first.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); setState(() { _isExpense = false; _amountCtrl.clear(); }); },
          child: const Text('Add Income Instead'),
        ),
      ],
    ));
  }

  void _showInsufficientDialog(double balance) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6D00)),
        SizedBox(width: 10),
        Text('Insufficient Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ]),
      content: Text('Available: ${UserService.currency}${balance.toStringAsFixed(2)}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currency = UserService.currency;
    final primary  = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: const Text('Add Transaction',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
              children: [_manualTab(currency, primary), _voiceTab(primary), _scanTab(primary)],
            ),
          ),
        ],
      ),
    );
  }

  // ── Manual Tab ────────────────────────────────────────────
  Widget _manualTab(String currency, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Row(children: [
              _toggleBtn('Expense', true, const Color(0xFFFF5252), Icons.arrow_upward_rounded),
              _toggleBtn('Income', false, primary, Icons.arrow_downward_rounded),
            ]),
          ),
          const SizedBox(height: 16),

          // Amount + note
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(currency, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                        color: _isExpense ? const Color(0xFFFF5252) : primary)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                            color: _isExpense ? const Color(0xFFFF5252) : primary),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.grey.shade200, fontSize: 36, fontWeight: FontWeight.bold),
                          border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade100, height: 24),
                Text('Note', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Swiggy, Uber, Netflix...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_autoDetected && _isExpense)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.auto_awesome_rounded, size: 12, color: primary),
                          const SizedBox(width: 4),
                          Text('Auto', style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category
          if (_isExpense) ...[
            Row(children: [
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 8),
              if (_autoDetected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Auto-detected', style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _cats.map((cat) {
                final label  = cat['label'] as String;
                final icon   = cat['icon'] as IconData;
                final color  = Color(cat['color'] as int);
                final active = _selectedCat == label;
                return GestureDetector(
                  onTap: () => setState(() { _selectedCat = label; _autoDetected = false; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? color : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? color : Colors.grey.shade200),
                      boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 16, color: active ? Colors.white : color),
                      const SizedBox(width: 6),
                      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : Colors.grey.shade700)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Date
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context, initialDate: _selectedDate,
                firstDate: DateTime(2020), lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.calendar_today_rounded, size: 18, color: primary),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Date', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  Text(_formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isExpense
                    ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                    : [primary, primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: (_isExpense ? const Color(0xFFFF5252) : primary).withValues(alpha: 0.35),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_isExpense ? 'Save Expense' : 'Save Income',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool isExp, Color color, IconData icon) {
    final active = _isExpense == isExp;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _isExpense = isExp; _autoDetected = false; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
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
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Voice Tab ─────────────────────────────────────────────
  Widget _voiceTab(Color primary) {
    final hasTranscript = _voiceTranscript.isNotEmpty;
    final examples = ['Swiggy 200', 'Uber ride 150', 'Netflix 649', 'Grocery 1200'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Mic button
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 130, height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                      : [primary, primary.withValues(alpha: 0.75)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? const Color(0xFFFF5252) : primary)
                        .withValues(alpha: _isListening ? 0.5 : 0.3),
                    blurRadius: _isListening ? 36 : 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 60, color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isListening ? 'Listening...' : 'Voice Input',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            !_voiceReady
                ? 'Microphone not available on this device'
                : _voiceStatus,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isListening
                  ? const Color(0xFFFF5252)
                  : Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Live transcript
          if (hasTranscript || _isListening) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isListening
                    ? const Color(0xFFFF5252).withValues(alpha: 0.05)
                    : primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isListening
                      ? const Color(0xFFFF5252).withValues(alpha: 0.3)
                      : primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                      _isListening ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded,
                      size: 14,
                      color: _isListening ? const Color(0xFFFF5252) : primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isListening ? 'Hearing...' : 'You said',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: _isListening ? const Color(0xFFFF5252) : primary,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    _voiceTranscript.isEmpty ? '...' : _voiceTranscript,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Parsed result preview
          if (hasTranscript && !_isListening) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: primary),
                    const SizedBox(width: 6),
                    Text('Detected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
                  ]),
                  const SizedBox(height: 12),
                  _voiceResultRow('Amount', _amountCtrl.text.isEmpty ? '—' : '${UserService.currency}${_amountCtrl.text}', Icons.attach_money_rounded),
                  const SizedBox(height: 8),
                  _voiceResultRow('Category', _selectedCat, Icons.category_rounded),
                  const SizedBox(height: 8),
                  _voiceResultRow('Note', _noteCtrl.text.isEmpty ? '—' : _noteCtrl.text, Icons.notes_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Save button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.8)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save Transaction', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _voiceTranscript = '';
                _voiceStatus = 'Tap the mic to start';
                _amountCtrl.clear();
                _noteCtrl.clear();
                _selectedCat = 'Food';
                _autoDetected = false;
              }),
              child: Text('Clear & Try Again', style: TextStyle(color: Colors.grey.shade500)),
            ),
            const SizedBox(height: 8),
          ],

          // Examples hint (shown when idle)
          if (!hasTranscript && !_isListening) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lightbulb_outline_rounded, color: Colors.amber.shade600, size: 16),
                    const SizedBox(width: 6),
                    const Text('Try saying...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: examples.map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text('"$e"', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _voiceResultRow(String label, String value, IconData icon) {
    return Row(children: [
      Icon(icon, size: 14, color: Colors.grey.shade400),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
    ]);
  }

  // ── Scan Tab ──────────────────────────────────────────────
  Widget _scanTab(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primary.withValues(alpha: 0.4), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16)],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.camera_alt_rounded, size: 48, color: primary),
                ),
                const SizedBox(height: 12),
                Text('Scan Bill / Receipt', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 28),
            const Text('Auto-extracts amount & date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Point your camera at any bill or receipt',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
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
