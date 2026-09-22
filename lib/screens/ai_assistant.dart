import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/savings_provider.dart';
import '../services/user_service.dart';

const _geminiApiKey = 'AIzaSyDSoUlDKf7XZhOOljMrbC2gElKwcD0cMmw';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _isGenerating = false;

  late final List<Map<String, dynamic>> _messages;

  final _suggestions = [
    'Where am I spending too much?',
    'How can I save more this month?',
    'Am I on track with my goals?',
    'Show my financial summary',
  ];

  @override
  void initState() {
    super.initState();
    final name = UserService.name.trim();
    final firstName = name.isNotEmpty ? (name.contains(' ') ? name.split(' ').first : name) : 'there';
    _messages = [
      {
        'text': 'Hi $firstName! 👋 I\'m your AI financial assistant. Ask me anything about your spending, savings, budget, or goals!',
        'isAi': true,
      },
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isGenerating) return;

    setState(() {
      _messages.add({'text': trimmed, 'isAi': false});
      _ctrl.clear();
      _isGenerating = true;
    });
    _scrollToBottom();

    final ep = context.read<ExpenseProvider>();
    final gp = context.read<GoalProvider>();
    final sp = context.read<SavingsProvider>();
    final currency = UserService.currency;
    final budget = UserService.budget;
    final income = UserService.income;
    final balance = ep.balance;
    final totalExpenses = ep.totalExpenses;
    final savings = sp.savings;
    final categoryTotals = ep.categoryTotals;

    String reply = '';

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
        generationConfig: GenerationConfig(temperature: 0.7),
      );

      final catSummary = categoryTotals.entries
          .map((e) => '${e.key}: $currency${e.value.toStringAsFixed(0)}')
          .join(', ');

      final goalsSummary = gp.goals.isEmpty
          ? 'None'
          : gp.goals
              .map((g) => '${g.name}: $currency${g.savedAmount.toStringAsFixed(0)} / $currency${g.targetAmount.toStringAsFixed(0)} (${(g.progress * 100).toInt()}%)')
              .join('; ');

      final systemPrompt = '''
You are a warm, concise, and helpful personal finance advisor inside a mobile app.
User's Financial Profile:
- Name: ${UserService.name}
- Currency: $currency
- Monthly Income: $currency${income.toStringAsFixed(0)}
- Monthly Budget: $currency${budget.toStringAsFixed(0)}
- Current Balance: $currency${balance.toStringAsFixed(2)}
- Total Expenses Logged: $currency${totalExpenses.toStringAsFixed(0)}
- Current Savings Pot: $currency${savings.toStringAsFixed(0)}
- Spending by Category: ${catSummary.isEmpty ? 'No expenses recorded yet' : catSummary}
- Active Goals: $goalsSummary

Instructions:
1. Answer the user's question directly, accurately and concisely using their actual numbers and currency ($currency).
2. Keep response under 4-5 bullet points or short paragraphs.
3. Use friendly emojis.
4. If they have no expenses or budget set, gently advise them on setting one up.
''';

      final response = await model.generateContent([
        Content.text('$systemPrompt\n\nUser query: $trimmed')
      ]);

      reply = response.text?.trim() ?? '';
    } catch (_) {
      reply = _generateLocalReply(trimmed, ep, gp, sp);
    }

    if (reply.isEmpty) {
      reply = _generateLocalReply(trimmed, ep, gp, sp);
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _messages.add({'text': reply, 'isAi': true});
      });
      _scrollToBottom();
    }
  }

  String _generateLocalReply(
      String query, ExpenseProvider ep, GoalProvider gp, SavingsProvider sp) {
    final currency = UserService.currency;
    final budget = UserService.budget;
    final totalSpent = ep.totalExpenses;
    final totals = ep.categoryTotals;
    final lower = query.toLowerCase();

    if (lower.contains('spending') || lower.contains('too much') || lower.contains('where')) {
      if (totals.isEmpty) {
        return '📊 You haven\'t logged any expenses yet! Once you add transactions, I will analyze your top spending categories.';
      }
      final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final buffer = StringBuffer('📊 Spending Breakdown:\n\n');
      for (final e in sorted.take(3)) {
        buffer.writeln('• ${e.key}: $currency${e.value.toStringAsFixed(0)}');
      }
      buffer.writeln('\n💡 Your highest category is ${top.key}. Try cutting down discretionary spending here to save more!');
      return buffer.toString();
    }

    if (lower.contains('save') || lower.contains('saving')) {
      final pot = sp.savings;
      final remaining = budget > 0 ? budget - totalSpent : 0.0;
      return '💡 Personalized Saving Plan:\n\n'
          '• Current Savings Pot: $currency${pot.toStringAsFixed(0)}\n'
          '${budget > 0 ? "• Budget Left This Month: $currency${remaining > 0 ? remaining.toStringAsFixed(0) : '0'}\n" : ""}'
          '• Allocate 20% of extra income straight into your Savings Pot\n'
          '• Review recurring subscriptions and food delivery orders 🎉';
    }

    if (lower.contains('goal') || lower.contains('track')) {
      if (gp.goals.isEmpty) {
        return '🎯 You don\'t have any active goals yet. Tap the Goals tab to set a target like a laptop, vacation, or emergency fund!';
      }
      final buffer = StringBuffer('🎯 Goal Progress:\n\n');
      for (final g in gp.goals) {
        final days = g.deadline.difference(DateTime.now()).inDays;
        buffer.writeln(
            '• ${g.name}: ${(g.progress * 100).toInt()}% ($currency${g.savedAmount.toStringAsFixed(0)} / $currency${g.targetAmount.toStringAsFixed(0)}) — ${days > 0 ? "$days days left" : "Deadline passed"}');
      }
      return buffer.toString();
    }

    // Default summary
    final inc = UserService.income;
    return '📈 Financial Overview:\n\n'
        '• Monthly Income: $currency${inc.toStringAsFixed(0)}\n'
        '• Total Spent: $currency${totalSpent.toStringAsFixed(0)}\n'
        '• Available Balance: $currency${ep.balance.toStringAsFixed(2)}\n'
        '• Savings Pot: $currency${sp.savings.toStringAsFixed(0)}\n'
        '${budget > 0 ? "• Budget Adherence: ${((totalSpent / budget) * 100).clamp(0, 999).toStringAsFixed(0)}% used\n" : ""}\n'
        'Let me know if you need specific tips on budgeting, goals, or cutting expenses!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Color(0xFF7C4DFF), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Always online',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF00C853))),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isGenerating ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _isGenerating) {
                  return _typingIndicator();
                }
                return _bubble(_messages[i]);
              },
            ),
          ),
          if (_messages.length == 1 && !_isGenerating)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _send(_suggestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.3)),
                    ),
                    child: Text(_suggestions[i],
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF7C4DFF))),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: const Color(0xFFF5F7FA),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: _send,
                    decoration: const InputDecoration(
                      hintText: 'Ask me anything about your finances...',
                      prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _send(_ctrl.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C4DFF),
                      shape: BoxShape.circle,
                    ),
                    child: _isGenerating
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Thinking...',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> msg) {
    final isAi = msg['isAi'] as bool;
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isAi ? Colors.white : const Color(0xFF7C4DFF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAi ? 4 : 16),
            bottomRight: Radius.circular(isAi ? 16 : 4),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          msg['text'] as String,
          style: TextStyle(
              color: isAi ? Colors.black87 : Colors.white,
              fontSize: 14,
              height: 1.5),
        ),
      ),
    );
  }
}
