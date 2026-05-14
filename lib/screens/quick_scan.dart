import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/user_service.dart';

class QuickScanScreen extends StatefulWidget {
  const QuickScanScreen({super.key});
  @override
  State<QuickScanScreen> createState() => _QuickScanScreenState();
}

class _QuickScanScreenState extends State<QuickScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  bool _scanned       = false;
  bool _scanning      = false;
  double? _detectedAmount;
  String  _detectedNote = '';
  String  _detectedCat  = 'Other';
  DateTime _detectedDate = DateTime.now();

  // Simulated scan results for demo
  static const _mockResults = [
    {'amount': 249.0,  'note': 'Swiggy Order',      'cat': 'Food'},
    {'amount': 1299.0, 'note': 'Amazon Purchase',   'cat': 'Shopping'},
    {'amount': 649.0,  'note': 'Netflix Subscription', 'cat': 'Bills'},
    {'amount': 180.0,  'note': 'Uber Ride',          'cat': 'Transport'},
    {'amount': 350.0,  'note': 'Pharmacy',           'cat': 'Health'},
  ];

  static const _catIcons = <String, IconData>{
    'Food'         : Icons.restaurant_rounded,
    'Transport'    : Icons.directions_car_rounded,
    'Shopping'     : Icons.shopping_bag_rounded,
    'Bills'        : Icons.receipt_long_rounded,
    'Health'       : Icons.favorite_rounded,
    'Education'    : Icons.school_rounded,
    'Entertainment': Icons.movie_rounded,
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
    'Other'        : Color(0xFF9E9E9E),
  };

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() { _scanning = true; _scanned = false; });
    _scanCtrl.repeat(reverse: true);

    // Simulate scan completing after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _scanCtrl.stop();
      final result = _mockResults[
          DateTime.now().millisecond % _mockResults.length];
      setState(() {
        _scanning      = false;
        _scanned       = true;
        _detectedAmount = result['amount'] as double;
        _detectedNote   = result['note'] as String;
        _detectedCat    = result['cat'] as String;
        _detectedDate   = DateTime.now();
      });
    });
  }

  void _reset() => setState(() { _scanned = false; _scanning = false; });

  Future<void> _saveExpense() async {
    if (_detectedAmount == null) return;
    final provider = context.read<ExpenseProvider>();
    final balance  = provider.balance;

    if (balance <= 0) {
      _snack('Balance is empty. Add income first.', error: true);
      return;
    }
    if (_detectedAmount! > balance) {
      _snack('Insufficient balance: ${UserService.currency}${balance.toStringAsFixed(2)}',
          error: true);
      return;
    }

    await provider.addExpense(Expense(
      amount   : _detectedAmount!,
      category : _detectedCat,
      note     : _detectedNote,
      date     : _detectedDate,
      isExpense: true,
    ));

    _snack('${UserService.currency}${_detectedAmount!.toStringAsFixed(0)} saved as $_detectedCat',
        error: false);
    _reset();
  }

  void _snack(String msg, {required bool error}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFFF5252)
            : Theme.of(context).colorScheme.primary,
      ));

  @override
  Widget build(BuildContext context) {
    final primary   = Theme.of(context).colorScheme.primary;
    final currency  = UserService.currency;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.document_scanner_rounded,
                      color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Scan',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Scan a bill or receipt',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Scanner viewfinder
                  _scannerBox(primary),
                  const SizedBox(height: 20),

                  // Result card (shown after scan)
                  if (_scanned && _detectedAmount != null)
                    _resultCard(currency, primary),

                  if (!_scanned && !_scanning) ...[
                    const SizedBox(height: 8),
                    Text('Point your camera at any bill or receipt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                    const SizedBox(height: 20),
                    // Scan button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startScan,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Start Scanning'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _tipsCard(),
                  ],

                  if (_scanning) ...[
                    const SizedBox(height: 16),
                    Text('Scanning...',
                        style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 6),
                    Text('Detecting amount and category',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scanner viewfinder box ────────────────────────────────
  Widget _scannerBox(Color primary) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Dark background with subtle grid
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.grey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Corner brackets
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CustomPaint(painter: _CornerPainter(primary)),
              ),
            ),

            // Animated scan line
            if (_scanning)
              AnimatedBuilder(
                animation: _scanAnim,
                builder: (_, __) => Positioned(
                  top: 32 + (_scanAnim.value * 196),
                  left: 32,
                  right: 32,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          primary,
                          primary,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: primary.withValues(alpha: 0.6),
                            blurRadius: 8)
                      ],
                    ),
                  ),
                ),
              ),

            // Center content
            Center(
              child: _scanned
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded,
                              color: primary, size: 40),
                        ),
                        const SizedBox(height: 12),
                        Text('Scan Complete!',
                            style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    )
                  : _scanning
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40, height: 40,
                              child: CircularProgressIndicator(
                                  color: primary, strokeWidth: 3),
                            ),
                            const SizedBox(height: 12),
                            Text('Analyzing...',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.document_scanner_rounded,
                                color: Colors.white30, size: 48),
                            const SizedBox(height: 8),
                            const Text('Tap Scan to start',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 13)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Result card ───────────────────────────────────────────
  Widget _resultCard(String currency, Color primary) {
    final color = _catColors[_detectedCat] ?? Colors.grey;
    final icon  = _catIcons[_detectedCat] ?? Icons.category_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: primary.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4))
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
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.auto_awesome_rounded,
                    color: primary, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Detected from scan',
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: _reset,
                child: Icon(Icons.refresh_rounded,
                    color: Colors.grey.shade400, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_detectedNote,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_detectedCat,
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(
                '$currency${_detectedAmount!.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF5252)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Discard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade300),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saveExpense,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Save Expense'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tips card ─────────────────────────────────────────────
  Widget _tipsCard() {
    final tips = [
      'Place the bill flat on a surface',
      'Ensure good lighting for better accuracy',
      'Keep the full bill within the frame',
      'Works with restaurant bills, receipts & invoices',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: Colors.amber.shade600, size: 18),
              const SizedBox(width: 8),
              const Text('Tips for best results',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(top: 5, right: 8),
                  decoration: BoxDecoration(
                      color: Colors.amber.shade600, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(t,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12,
                          height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Corner bracket painter ────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;

    // Top-left
    canvas.drawLine(Offset.zero, Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, len), paint);
    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
