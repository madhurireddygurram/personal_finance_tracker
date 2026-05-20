import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'setup.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late final bool _hasSavedAccount;

  // Login controllers
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginObscure = true;

  // Signup controllers
  final _signupNameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPassCtrl = TextEditingController();
  final _signupConfirmCtrl = TextEditingController();
  bool _signupObscure = true;
  bool _signupConfirmObscure = true;

  @override
  void initState() {
    super.initState();
    _hasSavedAccount = UserService.hasAccount;
    _tab = TabController(length: 2, vsync: this);
    if (_hasSavedAccount) {
      _loginEmailCtrl.text = UserService.email;
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPassCtrl.dispose();
    _signupConfirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFFFF5252)
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // ── Login ─────────────────────────────────────────────────
  Future<void> _login() async {
    final email = _loginEmailCtrl.text.trim().toLowerCase();
    final pass = _loginPassCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _snack('Please fill in all fields');
      return;
    }
    if (!email.contains('@')) {
      _snack('Enter a valid email address');
      return;
    }

    final savedEmail = UserService.email;
    final savedPass = UserService.password;

    if (savedEmail.isEmpty) {
      _snack('No account found. Please sign up first');
      return;
    }
    if (email != savedEmail || pass != savedPass) {
      _snack('Incorrect email or password');
      return;
    }

    await UserService.setLoggedIn(true);
    // Restore setupDone so app skips login on next restart
    await UserService.restoreSetupDone();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserService.income > 0 ? const HomeScreen() : const SetupScreen(),
      ),
    );
  }

  // ── Signup ────────────────────────────────────────────────
  Future<void> _signup() async {
    final name = _signupNameCtrl.text.trim();
    final email = _signupEmailCtrl.text.trim().toLowerCase();
    final pass = _signupPassCtrl.text.trim();
    final confirm = _signupConfirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _snack('Please fill in all fields');
      return;
    }
    if (name.length < 2) {
      _snack('Name must be at least 2 characters');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _snack('Enter a valid email address');
      return;
    }
    if (pass.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    if (pass != confirm) {
      _snack('Passwords do not match');
      return;
    }
    if (_hasSavedAccount && email == UserService.email) {
      _snack('Account already exists. Please login instead.', error: false);
      _loginEmailCtrl.text = email;
      _loginPassCtrl.clear();
      _tab.animateTo(0);
      return;
    }

    await UserService.saveUser(name: name, email: email, password: pass);
    await UserService.setLoggedIn(true);

    if (!mounted) return;
    _snack('Account created! Welcome, $name', error: false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
  }

  // ── Forgot Password ───────────────────────────────────────
  void _forgotPassword() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address. Your password will be shown if the account exists.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final entered = emailCtrl.text.trim();
              Navigator.pop(ctx);
              if (entered.isEmpty) {
                _snack('Please enter your email');
                return;
              }
              if (entered != UserService.email) {
                _snack('No account found with this email');
                return;
              }
              // Show password in a second dialog
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    'Your Password',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_open_rounded,
                          color: Color(0xFF00C853),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          UserService.password,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Find Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 42,
                  color: Color(0xFF00C853),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Finance AI',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Your personal money manager',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 36),
              if (!_hasSavedAccount) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Show the correct form based on tab index
              _hasSavedAccount
                  ? _loginForm()
                  : AnimatedBuilder(
                      animation: _tab,
                      builder: (context, child) =>
                          _tab.index == 0 ? _loginForm() : _signupForm(),
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          controller: _loginEmailCtrl,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _passwordField(
          controller: _loginPassCtrl,
          label: 'Password',
          obscure: _loginObscure,
          onToggle: () => setState(() => _loginObscure = !_loginObscure),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: Color(0xFF00C853),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        ElevatedButton(onPressed: _login, child: const Text('Login')),
      ],
    );
  }

  Widget _signupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          controller: _signupNameCtrl,
          label: 'Full Name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _signupEmailCtrl,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _passwordField(
          controller: _signupPassCtrl,
          label: 'Password',
          obscure: _signupObscure,
          onToggle: () => setState(() => _signupObscure = !_signupObscure),
        ),
        const SizedBox(height: 10),
        _passwordField(
          controller: _signupConfirmCtrl,
          label: 'Confirm Password',
          obscure: _signupConfirmObscure,
          onToggle: () =>
              setState(() => _signupConfirmObscure = !_signupConfirmObscure),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _signup, child: const Text('Create Account')),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
