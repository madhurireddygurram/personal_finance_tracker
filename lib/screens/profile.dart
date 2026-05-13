import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/user_service.dart';
import '../services/gamification_service.dart';
import 'ai_assistant.dart';
import 'gamification.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _syncOn = true;
  bool _pinLock = false;

  // Read language from Hive so it persists across sessions
  String get _language => UserService.language;

  bool get _darkMode => themeModeNotifier.value == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.profile,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _profileHeader(l),
          const SizedBox(height: 24),
          _section(l.settings, [
            _switchTile(Icons.dark_mode_outlined, l.darkMode, _darkMode, (v) {
              themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
              setState(() {});
            }),
            _divider(),
            _arrowTile(Icons.language_outlined, l.language, _language,
                () => _showLanguagePicker(l)),
            _divider(),
            _arrowTile(Icons.currency_exchange_outlined, l.currency,
                _currentCurrencyLabel.split('–').first.trim(),
                () => _showCurrencyPicker()),
          ]),
          const SizedBox(height: 16),
          _section(l.security, [
            _switchTile(Icons.pin_outlined, l.pinLock, _pinLock, (v) {
              if (v) _showPinSetupDialog();
              else setState(() => _pinLock = false);
            }),
            _divider(),
            _arrowTile(Icons.fingerprint_rounded, l.fingerprint, '', () {
              _snack('Biometric authentication enabled');
            }),
          ]),
          const SizedBox(height: 16),
          _section('Backup & Data', [
            _switchTile(Icons.cloud_sync_outlined, l.cloudSync, _syncOn, (v) {
              setState(() => _syncOn = v);
              _snack(v ? 'Cloud sync enabled' : 'Cloud sync disabled');
            }),
            _divider(),
            _arrowTile(Icons.download_outlined, l.exportPdf, '', _exportPdf),
          ]),
          const SizedBox(height: 16),
          _section('More', [
            _arrowTile(Icons.chat_outlined, 'AI Assistant', '', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
            }),
            _divider(),
            _arrowTile(Icons.emoji_events_outlined, l.achievements,
                '${GamificationService.streak} day streak',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GamificationScreen()))),
            _divider(),
            _arrowTile(Icons.group_outlined, l.splitExpenses, '', _showSplitExpenses),
          ]),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
            label: Text(l.logout,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Full currency map — label → symbol (same as setup)
  static const _currencyMap = {
    'INR – Indian Rupee (₹)'        : '₹',
    'USD – US Dollar (\$)'           : '\$',
    'EUR – Euro (€)'                 : '€',
    'GBP – British Pound (£)'        : '£',
    'JPY – Japanese Yen (¥)'         : '¥',
    'AUD – Australian Dollar (A\$)'  : 'A\$',
    'CAD – Canadian Dollar (C\$)'    : 'C\$',
    'CHF – Swiss Franc (Fr)'         : 'Fr',
    'SGD – Singapore Dollar (S\$)'   : 'S\$',
    'AED – UAE Dirham (د.إ)'         : 'د.إ',
    'SAR – Saudi Riyal (﷼)'          : '﷼',
    'MYR – Malaysian Ringgit (RM)'   : 'RM',
    'THB – Thai Baht (฿)'            : '฿',
    'KRW – South Korean Won (₩)'     : '₩',
    'CNY – Chinese Yuan (¥)'         : '¥',
    'BRL – Brazilian Real (R\$)'     : 'R\$',
    'MXN – Mexican Peso (MX\$)'      : 'MX\$',
    'ZAR – South African Rand (R)'   : 'R',
    'NGN – Nigerian Naira (₦)'       : '₦',
    'IDR – Indonesian Rupiah (Rp)'   : 'Rp',
    'PKR – Pakistani Rupee (₨)'      : '₨',
    'BDT – Bangladeshi Taka (৳)'     : '৳',
    'NZD – New Zealand Dollar (NZ\$)': 'NZ\$',
    'HKD – Hong Kong Dollar (HK\$)'  : 'HK\$',
  };

  static const _languages = ['English', 'Hindi', 'Telugu', 'Tamil', 'Kannada', 'Malayalam', 'Bengali', 'Marathi'];

  // Find the display label for the currently saved symbol
  String get _currentCurrencyLabel {
    final sym = UserService.currency;
    return _currencyMap.entries
        .firstWhere((e) => e.value == sym,
            orElse: () => _currencyMap.entries.first)
        .key;
  }

  // ── Profile header — real name & email ────────────────────
  Widget _profileHeader(AppLocalizations l) {
    final name = UserService.name;
    final email = UserService.email;
    final initial = UserService.initial;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C853)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(email,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(l.activeMember,
                      style: TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _showEditProfile,
          ),
        ],
      ),
    );
  }

  // ── Section container ─────────────────────────────────────
  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade500,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _divider() => Divider(
      height: 1, indent: 56, endIndent: 16, color: Colors.grey.shade100);

  // ── Actions ───────────────────────────────────────────────
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: UserService.name);
    final emailCtrl = TextEditingController(text: UserService.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                if (name.isEmpty || email.isEmpty) {
                  _snack('Fields cannot be empty');
                  return;
                }
                await UserService.updateProfile(name: name, email: email);
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {});
                _snack('Profile updated successfully');
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinSetupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set PIN',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter 4-digit PIN'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (ctrl.text.length == 4) {
                setState(() => _pinLock = true);
                _snack('PIN set successfully');
              } else {
                _snack('PIN must be exactly 4 digits');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _exportPdf() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Export Report',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exportOption(Icons.calendar_view_month_rounded, 'This Month'),
            _exportOption(Icons.date_range_rounded, 'Last 3 Months'),
            _exportOption(Icons.calendar_today_rounded, 'This Year'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _exportOption(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        _snack('Generating $label PDF report...');
      },
    );
  }

  void _showSplitExpenses() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Split Expenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const TextField(
                decoration: InputDecoration(
                    labelText: 'Expense Name',
                    prefixIcon: Icon(Icons.receipt_outlined))),
            const SizedBox(height: 14),
            const TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Total Amount',
                    prefixIcon: Icon(Icons.currency_rupee))),
            const SizedBox(height: 14),
            const TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Number of People',
                    prefixIcon: Icon(Icons.group_outlined))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _snack('Split expense created');
              },
              child: const Text('Split & Share'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(AppLocalizations l) {
    String selected = _language; // local copy for sheet state
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l.selectLanguage,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            ..._languages.map((lang) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Icon(
                Icons.language_outlined,
                color: selected == lang ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              title: Text(lang),
              trailing: selected == lang
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00C853))
                  : null,
              onTap: () async {
                setSheet(() => selected = lang);  // update checkmark in sheet
                await UserService.setLanguage(lang); // persist to Hive
                // Update locale so entire app rebuilds in new language
                localeNotifier.value = Locale(
                  lang == 'Hindi' ? 'hi' : lang == 'Telugu' ? 'te' : 'en');
                setState(() {}); // update subtitle on profile tile
                Navigator.pop(ctx);
                _snack('Language changed to $lang');
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 16),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(alignment: Alignment.centerLeft,
                  child: Text('Select Currency',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: _currencyMap.entries.map((entry) {
                  final isSelected = UserService.currency == entry.value;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(entry.value,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade600)),
                      ),
                    ),
                    title: Text(entry.key.split('–').last.trim(),
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(entry.key.split('–').first.trim(),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00C853))
                        : null,
                    onTap: () async {
                      await UserService.saveSetup(
                        income  : UserService.income,
                        budget  : UserService.budget,
                        currency: entry.value,
                        goal    : UserService.goal,
                      );
                      if (!context.mounted) return;
                      setState(() {});
                      Navigator.pop(context);
                      _snack('Currency changed to ${entry.value}');
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              await UserService.logout();
              themeModeNotifier.value = ThemeMode.light;
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ── Tile widgets ──────────────────────────────────────────
  Widget _switchTile(IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: primary,
      ),
    );
  }

  Widget _arrowTile(IconData icon, String label, String subtitle,
      VoidCallback onTap) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

