import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/expense_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/savings_provider.dart';
import 'screens/splash.dart';
import 'services/hive_service.dart';
import 'services/user_service.dart';
import 'services/gamification_service.dart';
import 'services/theme_service.dart';

final themeModeNotifier   = ValueNotifier<ThemeMode>(ThemeMode.light);
final activeThemeNotifier = ValueNotifier<AppTheme>(ThemeService.themes.first);
final localeNotifier      = ValueNotifier<Locale>(const Locale('en'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await UserService.init();
  await GamificationService.init();
  activeThemeNotifier.value = ThemeService.active;
  // Load persisted language
  final lang = UserService.language;
  final langMap = {
    'Hindi': 'hi', 'Telugu': 'te', 'Tamil': 'ta', 'Kannada': 'kn', 
    'Malayalam': 'ml', 'Bengali': 'bn', 'Marathi': 'mr'
  };
  localeNotifier.value = Locale(langMap[lang] ?? 'en');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()..loadExpenses()),
        ChangeNotifierProvider(create: (_) => GoalProvider()..loadGoals()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()..load()),
      ],
      child: const FinanceApp(),
    ),
  );
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: activeThemeNotifier,
      builder: (_, appTheme, __) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (_, mode, __) => ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (_, locale, __) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Finance AI',
            themeMode: mode,
            theme: ThemeService.buildTheme(appTheme, Brightness.light),
            darkTheme: ThemeService.buildTheme(appTheme, Brightness.dark),
            locale: locale,
            supportedLocales: const [
              Locale('en'), Locale('hi'), Locale('te'),
              Locale('ta'), Locale('kn'), Locale('ml'),
              Locale('bn'), Locale('mr')
            ],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}
