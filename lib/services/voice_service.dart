import 'package:speech_to_text/speech_to_text.dart';

class VoiceResult {
  final double? amount;
  final String category;
  final String note;
  final String rawText;

  const VoiceResult({
    required this.amount,
    required this.category,
    required this.note,
    required this.rawText,
  });
}

class VoiceService {
  static final SpeechToText _speech = SpeechToText();
  static bool _initialized = false;

  static Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _initialized;
  }

  static bool get isAvailable => _speech.isAvailable;
  static bool get isListening => _speech.isListening;

  static Future<void> listen({
    required Function(String text) onResult,
    required Function() onDone,
  }) async {
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        } else {
          onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  static Future<void> stop() async {
    await _speech.stop();
  }

  // ── Smart parser ──────────────────────────────────────────
  static VoiceResult parse(String text) {
    final lower = text.toLowerCase().trim();

    double? amount;
    final amountMatch = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(lower);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!);
    }

    return VoiceResult(
      amount  : amount,
      category: _detectCategory(lower),
      note    : _buildNote(text, amount),
      rawText : text,
    );
  }

  static String _detectCategory(String text) {
    const keywords = <String, String>{
      'swiggy':'Food','zomato':'Food','dominos':'Food','pizza':'Food',
      'burger':'Food','mcdonalds':'Food','kfc':'Food','subway':'Food',
      'restaurant':'Food','cafe':'Food','coffee':'Food','tea':'Food',
      'lunch':'Food','dinner':'Food','breakfast':'Food','snack':'Food',
      'grocery':'Food','groceries':'Food','vegetables':'Food','fruits':'Food',
      'milk':'Food','hotel':'Food','biryani':'Food','food':'Food',
      'eat':'Food','eating':'Food','meal':'Food',
      'uber':'Transport','ola':'Transport','rapido':'Transport',
      'bus':'Transport','metro':'Transport','train':'Transport',
      'auto':'Transport','taxi':'Transport','petrol':'Transport',
      'fuel':'Transport','diesel':'Transport','parking':'Transport',
      'flight':'Transport','cab':'Transport','transport':'Transport',
      'travel':'Transport','commute':'Transport','ride':'Transport',
      'amazon':'Shopping','flipkart':'Shopping','myntra':'Shopping',
      'ajio':'Shopping','clothes':'Shopping','shirt':'Shopping',
      'shoes':'Shopping','dress':'Shopping','shopping':'Shopping',
      'mall':'Shopping','market':'Shopping','purchase':'Shopping',
      'bought':'Shopping','buy':'Shopping',
      'electricity':'Bills','water':'Bills','internet':'Bills',
      'wifi':'Bills','mobile':'Bills','recharge':'Bills',
      'netflix':'Bills','spotify':'Bills','hotstar':'Bills',
      'subscription':'Bills','rent':'Bills','emi':'Bills',
      'insurance':'Bills','bill':'Bills','utility':'Bills',
      'phone':'Bills','broadband':'Bills',
      'medicine':'Health','doctor':'Health','hospital':'Health',
      'pharmacy':'Health','clinic':'Health','gym':'Health',
      'health':'Health','medical':'Health','tablet':'Health',
      'chemist':'Health','fitness':'Health',
      'book':'Education','course':'Education','tuition':'Education',
      'college':'Education','school':'Education','fees':'Education',
      'exam':'Education','stationery':'Education','pen':'Education',
      'notebook':'Education','education':'Education','class':'Education',
      'movie':'Entertainment','cinema':'Entertainment','game':'Entertainment',
      'concert':'Entertainment','party':'Entertainment','outing':'Entertainment',
      'fun':'Entertainment','entertainment':'Entertainment',
    };
    for (final entry in keywords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return 'Other';
  }

  static String _buildNote(String text, double? amount) {
    String note = text;
    if (amount != null) {
      note = note.replaceAll(RegExp(r'\d+(?:\.\d{1,2})?'), '').trim();
    }
    const fillers = [
      'i spent','i paid','paid','spent','rupees','rs','inr',
      'dollars','for','on','at','the','a','an','to',
    ];
    for (final f in fillers) {
      note = note.replaceAll(RegExp('\\b$f\\b', caseSensitive: false), '');
    }
    note = note.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (note.isNotEmpty) note = note[0].toUpperCase() + note.substring(1);
    return note.isEmpty ? text : note;
  }
}
