import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home.dart';
import 'login.dart';
import 'onboarding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      // Route based on persisted state — never loses session between app restarts
      Widget next;
      if (UserService.isLoggedIn && UserService.setupDone) {
        next = const HomeScreen();        // returning user — go straight to app
      } else if (UserService.email.isNotEmpty) {
        next = const LoginScreen();       // account exists but not logged in
      } else if (UserService.onboardingDone) {
        next = const LoginScreen();       // saw onboarding, no account yet
      } else {
        next = const OnboardingScreen();  // very first launch
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        size: 50, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Finance AI',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  const Text('Take Control of Your Money',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

