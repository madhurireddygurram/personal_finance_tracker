import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'login.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = const [
    _OPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Track Expenses Easily',
      subtitle: 'Log every rupee you spend in seconds.\nKnow where your money goes.',
      color: Color(0xFF00C853),
    ),
    _OPage(
      icon: Icons.psychology_rounded,
      title: 'Get AI Insights',
      subtitle: 'Smart suggestions to help you\nsave more every month.',
      color: Color(0xFF7C4DFF),
    ),
    _OPage(
      icon: Icons.flag_rounded,
      title: 'Achieve Your Goals',
      subtitle: 'Set targets, track progress,\nand celebrate milestones.',
      color: Color(0xFFFF6D00),
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goLogin,
                child: const Text('Skip', style: TextStyle(color: Colors.grey)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  if (_page < _pages.length - 1) {
                    _ctrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  } else {
                    _goLogin();
                  }
                },
                child: Text(_page < _pages.length - 1 ? 'Next' : 'Get Started'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _goLogin() async {
    await UserService.setOnboardingDone();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

class _OPage extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;

  const _OPage(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: color),
          ),
          const SizedBox(height: 40),
          Text(title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(subtitle,
              style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

