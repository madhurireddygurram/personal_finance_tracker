import 'package:flutter/material.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  final _messages = <Map<String, dynamic>>[
    {
      'text': 'Hi Mahathi! 👋 I\'m your AI financial assistant. Ask me anything about your spending, savings, or goals!',
      'isAi': true,
    },
  ];

  final _suggestions = [
    'Where am I spending too much?',
    'How can I save ₹5000?',
    'Am I on track with my goals?',
    'Show my spending summary',
  ];

  final _aiReplies = {
    'Where am I spending too much?':
        '📊 Based on your data, you\'re overspending on:\n\n🍔 Food: ₹3,200 (budget: ₹2,000)\n🛍️ Shopping: ₹2,800 (budget: ₹1,500)\n\nTry cutting food delivery by 2x/week to save ₹800!',
    'How can I save ₹5000?':
        '💡 Here\'s your personalized saving plan:\n\n• Skip 4 food deliveries → ₹800\n• Cancel unused subscriptions → ₹649\n• Reduce transport → ₹500\n• Limit shopping → ₹3,051\n\nTotal: ₹5,000 saved! 🎉',
    'Am I on track with my goals?':
        '🎯 Goal Progress:\n\n💻 Laptop: 60% — On track! ✅\n✈️ Trip: 40% — Need ₹200 more/day\n🚗 Bike: 25% — Behind schedule ⚠️\n\nFocus on the Trip goal this month!',
    'Show my spending summary':
        '📈 This Month\'s Summary:\n\n💰 Income: ₹20,000\n💸 Expenses: ₹10,000\n💚 Savings: ₹10,000 (50%)\n\nTop categories:\n🍔 Food 35% | 🚕 Transport 25%\n🛍️ Shopping 20% | 📄 Bills 20%',
  };

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'isAi': false});
      _ctrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      final reply = _aiReplies[text] ??
          '🤔 Great question! Based on your spending patterns, I\'d recommend reviewing your budget categories. Would you like a detailed breakdown?';
      setState(() => _messages.add({'text': reply, 'isAi': true}));
      Future.delayed(const Duration(milliseconds: 100), () {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
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
                color: const Color(0xFF7C4DFF).withOpacity(0.15),
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
              itemCount: _messages.length,
              itemBuilder: (_, i) => _bubble(_messages[i]),
            ),
          ),
          if (_messages.length == 1)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _send(_suggestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF7C4DFF).withOpacity(0.3)),
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
                      hintText: 'Ask me anything...',
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
                    child: const Icon(Icons.send_rounded,
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
                color: Colors.black.withOpacity(0.05),
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

