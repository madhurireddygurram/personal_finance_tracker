import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/user_service.dart';

// ── Replace with your Gemini API key ──────────────────────────
// Get a free key at https://aistudio.google.com/app/apikey
const _geminiApiKey = 'AIzaSyDSoUlDKf7XZhOOljMrbC2gElKwcD0cMmw';

class QuickScanScreen extends StatefulWidget {
  const QuickScanScreen({super.key});
  @override
  State<QuickScanScreen> createState() => _QuickScanScreenState();
}

class _QuickScanScreenState extends State<QuickScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  bool _scanned    = false;
  bool _scanning   = false;
  bool _uploading  = false;
  XFile? _uploadedImage;
  double? _detectedAmount;
  String  _detectedNote = '';
  String  _detectedCat  = 'Other';
  DateTime _detectedDate = DateTime.now();

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
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  void _startScan() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return;
    setState(() { _scanning = true; _scanned = false; _uploadedImage = picked; });
    _scanCtrl.repeat(reverse: true);
    await _readBillWithAI(picked);
    _scanCtrl.stop();
  }

  void _reset() => setState(() {
    _scanned = false; _scanning = false;
    _uploading = false; _uploadedImage = null;
  });

  // ── Gemini Vision bill reader ─────────────────────────────
  Future<void> _uploadBill() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() { _uploading = true; _scanned = false; _uploadedImage = picked; });
    _scanCtrl.repeat(reverse: true);
    await _readBillWithAI(picked);
    _scanCtrl.stop();
  }

  Future<void> _readBillWithAI(XFile image) async {
    try {
      final bytes = await image.readAsBytes();

      // Detect mime type from file extension
      final ext  = image.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png'
                 : ext == 'webp' ? 'image/webp'
                 : 'image/jpeg';

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
        generationConfig: GenerationConfig(temperature: 0),
      );

      const prompt =
          'This is a bill or receipt image. Extract these 3 fields:\n'
          '1. The TOTAL amount to pay (just the final number, no currency symbol)\n'
          '2. The merchant or store name\n'
          '3. The expense category — choose exactly one from: Food, Transport, Shopping, Bills, Health, Education, Entertainment, Other\n\n'
          'Reply in EXACTLY this format with no extra text:\n'
          'AMOUNT: 249.50\n'
          'MERCHANT: Store Name\n'
          'CATEGORY: Food\n\n'
          'If this image is not a bill/receipt or the amount is not visible, reply with just: UNREADABLE';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mime, bytes),
        ])
      ]);

      if (!mounted) return;

      final raw  = response.text?.trim() ?? '';
      final text = raw.replaceAll('**', '').trim(); // strip markdown bold

      if (text.toUpperCase().contains('UNREADABLE') || text.isEmpty) {
        setState(() { _scanning = false; _uploading = false; });
        _showManualEntrySheet(image,
            message: 'Could not interpret the image. Please enter the details manually.');
        return;
      }

      double? amount;
      String merchant = 'Bill';
      String category = 'Other';

      for (final line in text.split('\n')) {
        final l = line.trim();
        if (l.startsWith('AMOUNT:')) {
          // strip any currency symbols before parsing
          final raw = l.replaceAll('AMOUNT:', '').trim()
              .replaceAll(RegExp(r'[^0-9.]'), '');
          amount = double.tryParse(raw);
        } else if (l.startsWith('MERCHANT:')) {
          merchant = l.replaceAll('MERCHANT:', '').trim();
          if (merchant.isEmpty) merchant = 'Bill';
        } else if (l.startsWith('CATEGORY:')) {
          final cat = l.replaceAll('CATEGORY:', '').trim();
          if (_catColors.containsKey(cat)) category = cat;
        }
      }

      if (amount == null || amount <= 0) {
        setState(() { _scanning = false; _uploading = false; });
        _showManualEntrySheet(image,
            message: 'Amount could not be detected. Please enter the details manually.',
            prefillNote: merchant, prefillCat: category);
        return;
      }

      setState(() {
        _scanning       = false;
        _uploading      = false;
        _scanned        = true;
        _detectedAmount = amount;
        _detectedNote   = merchant;
        _detectedCat    = category;
        _detectedDate   = DateTime.now();
      });

    } catch (e) {
      if (!mounted) return;
      setState(() { _scanning = false; _uploading = false; });
      _showManualEntrySheet(image,
          message: 'AI could not read the bill (${e.toString().split('\n').first}). Please enter the details manually.');
    }
  }

  // ── Manual entry fallback sheet ───────────────────────────
  void _showManualEntrySheet(XFile image, {
    String message = '',
    String prefillNote = '',
    String prefillCat = 'Other',
  }) {
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController(text: prefillNote);
    String selCat    = prefillCat;
    final currency   = UserService.currency;
    const categories = [
      'Food', 'Transport', 'Shopping', 'Bills',
      'Health', 'Education', 'Entertainment', 'Other',
    ];

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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),

                // Warning banner if message provided
                if (message.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6D00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF6D00).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Color(0xFFFF6D00), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(message,
                              style: const TextStyle(
                                  color: Color(0xFFFF6D00), fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text('Enter Bill Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Bill image preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(image.path,
                          height: 140, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(File(image.path),
                          height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),

                // Amount
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Total Amount *',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    prefixText: '$currency ',
                  ),
                ),
                const SizedBox(height: 12),

                // Note
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Merchant / Note',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Category
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: categories.map((cat) {
                    final active = selCat == cat;
                    final color  = _catColors[cat] ?? Colors.grey;
                    return GestureDetector(
                      onTap: () => setSheet(() => selCat = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? color : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? color : Colors.grey.shade200),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: active ? Colors.white : Colors.grey.shade700)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please enter a valid amount'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFFFF5252),
                      ));
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() {
                      _scanned        = true;
                      _uploading      = false;
                      _detectedAmount = amount;
                      _detectedNote   = noteCtrl.text.trim().isEmpty ? 'Bill' : noteCtrl.text.trim();
                      _detectedCat    = selCat;
                      _detectedDate   = DateTime.now();
                    });
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Confirm & Add Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
    final primary  = Theme.of(context).colorScheme.primary;
    final currency = UserService.currency;

    return SafeArea(
      child: Column(
        children: [
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
                  child: Icon(Icons.document_scanner_rounded, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Scan',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Scan or upload a bill',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
                  _scannerBox(primary),
                  const SizedBox(height: 20),

                  if (_scanned && _detectedAmount != null)
                    _resultCard(currency, primary),

                  if (!_scanned && !_scanning && !_uploading) ...[
                    const SizedBox(height: 8),
                    Text('Point your camera at any bill or receipt',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Scan Bill with Camera'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _uploadBill,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Upload Bill from Gallery'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _tipsCard(),
                  ],

                  if (_scanning || _uploading) ...[
                    const SizedBox(height: 16),
                    Text('Reading bill with AI...',
                        style: TextStyle(
                            color: primary, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text('Gemini AI is extracting amount and details',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
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

  Widget _scannerBox(Color primary) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.grey.shade900],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CustomPaint(painter: _CornerPainter(primary)),
              ),
            ),
            if (_scanning)
              AnimatedBuilder(
                animation: _scanAnim,
                builder: (_, __) => Positioned(
                  top: 32 + (_scanAnim.value * 196),
                  left: 32, right: 32,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent, primary, primary, Colors.transparent,
                      ]),
                      boxShadow: [BoxShadow(
                          color: primary.withValues(alpha: 0.6), blurRadius: 8)],
                    ),
                  ),
                ),
              ),
            Center(
              child: _scanned
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, color: primary, size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text('Bill Read!',
                          style: TextStyle(
                              color: primary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ])
                  : (_scanning || _uploading)
                      ? Column(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(
                            width: 40, height: 40,
                            child: CircularProgressIndicator(color: primary, strokeWidth: 3),
                          ),
                          const SizedBox(height: 12),
                          Text(_uploading ? 'AI Reading...' : 'Analyzing...',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ])
                      : _uploadedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(_uploadedImage!.path,
                                      fit: BoxFit.cover, width: double.infinity)
                                  : Image.file(File(_uploadedImage!.path),
                                      fit: BoxFit.cover, width: double.infinity),
                            )
                          : Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.document_scanner_rounded,
                                  color: Colors.white30, size: 48),
                              const SizedBox(height: 8),
                              const Text('Tap Scan to start',
                                  style: TextStyle(color: Colors.white38, fontSize: 13)),
                            ]),
            ),
          ],
        ),
      ),
    );
  }

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
        boxShadow: [BoxShadow(
            color: primary.withValues(alpha: 0.1),
            blurRadius: 16, offset: const Offset(0, 4))],
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
                child: Icon(Icons.auto_awesome_rounded, color: primary, size: 16),
              ),
              const SizedBox(width: 8),
              Text(_uploadedImage != null ? 'Detected from uploaded bill' : 'Detected from scan',
                  style: TextStyle(
                      color: primary, fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: _reset,
                child: Icon(Icons.refresh_rounded, color: Colors.grey.shade400, size: 20),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_detectedCat,
                        style: TextStyle(
                            color: color, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text('$currency${_detectedAmount!.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      color: Color(0xFFFF5252))),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome_rounded,
                color: Theme.of(context).colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            const Text('AI Bill Reading',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          ...[
            'Upload any bill, receipt or invoice image',
            'AI automatically reads the amount and merchant',
            'If unreadable, you can enter details manually',
            'Works with restaurant bills, shopping receipts & more',
          ].map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(top: 5, right: 8),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle),
                ),
                Expanded(child: Text(t,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

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
    canvas.drawLine(Offset.zero, Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, len), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
