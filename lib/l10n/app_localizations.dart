import 'package:flutter/material.dart';

class AppLocalizations {
  final String languageCode;
  const AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)
        ?? const AppLocalizations('en');
  }

  // ── General ───────────────────────────────────────────────
  String get appName        => _t('Finance AI',       'फाइनेंस AI',      'ఫైనాన్స్ AI');
  String get hello          => _t('Hello',            'नमस्ते',           'హలో');
  String get save           => _t('Save',             'सहेजें',           'సేవ్');
  String get cancel         => _t('Cancel',           'रद्द करें',        'రద్దు');
  String get delete         => _t('Delete',           'हटाएं',            'తొలగించు');
  String get edit           => _t('Edit',             'संपादित करें',     'సవరించు');
  String get add            => _t('Add',              'जोड़ें',            'జోడించు');
  String get back           => _t('Back',             'वापस',             'వెనక్కి');
  String get next           => _t('Next',             'अगला',             'తదుపరి');
  String get done           => _t('Done',             'हो गया',           'పూర్తయింది');
  String get apply          => _t('Apply',            'लागू करें',        'వర్తించు');
  String get logout         => _t('Logout',           'लॉग आउट',          'లాగ్ అవుట్');
  String get confirm        => _t('Confirm',          'पुष्टि करें',      'నిర్ధారించు');
  String get seeAll         => _t('See all',          'सभी देखें',        'అన్నీ చూడు');
  String get optional       => _t('Optional',         'वैकल्पिक',         'ఐచ్ఛికం');
  String get active         => _t('Active',           'सक्रिय',           'యాక్టివ్');

  // ── Auth ──────────────────────────────────────────────────
  String get login          => _t('Login',            'लॉग इन',           'లాగిన్');
  String get signUp         => _t('Sign Up',          'साइन अप',          'సైన్ అప్');
  String get email          => _t('Email Address',    'ईमेल पता',         'ఇమెయిల్ చిరునామా');
  String get password       => _t('Password',         'पासवर्ड',          'పాస్‌వర్డ్');
  String get fullName       => _t('Full Name',        'पूरा नाम',         'పూర్తి పేరు');
  String get forgotPassword => _t('Forgot Password?', 'पासवर्ड भूल गए?', 'పాస్‌వర్డ్ మర్చిపోయారా?');
  String get createAccount  => _t('Create Account',   'खाता बनाएं',       'ఖాతా సృష్టించు');
  String get welcomeBack    => _t('Your personal money manager', 'आपका व्यक्तिगत धन प्रबंधक', 'మీ వ్యక్తిగత డబ్బు నిర్వాహకుడు');

  // ── Dashboard ─────────────────────────────────────────────
  String get totalBalance   => _t('Total Balance',    'कुल शेष',          'మొత్తం బ్యాలెన్స్');
  String get income         => _t('Income',           'आय',               'ఆదాయం');
  String get expenses       => _t('Expenses',         'खर्च',             'ఖర్చులు');
  String get savings        => _t('Savings',          'बचत',              'పొదుపు');
  String get monthlyBudget  => _t('Monthly Budget',   'मासिक बजट',        'నెలవారీ బడ్జెట్');
  String get overBudget     => _t('Over budget!',     'बजट से अधिक!',     'బడ్జెట్ మించింది!');
  String get smartInsights  => _t('Smart Insights',   'स्मार्ट अंतर्दृष्टि', 'స్మార్ట్ అంతర్దృష్టి');
  String get recentTxns     => _t('Recent Transactions', 'हाल के लेनदेन', 'ఇటీవలి లావాదేవీలు');
  String get quickActions   => _t('Quick Actions',    'त्वरित क्रियाएं',  'త్వరిత చర్యలు');
  String get spendingOverview => _t('Spending Overview', 'खर्च अवलोकन',  'వ్యయ అవలోకనం');
  String get goals          => _t('Goals',            'लक्ष्य',           'లక్ష్యాలు');
  String get noTxnsYet      => _t('No transactions yet', 'अभी कोई लेनदेन नहीं', 'ఇంకా లావాదేవీలు లేవు');
  String get addIncome      => _t('Add Income',       'आय जोड़ें',         'ఆదాయం జోడించు');
  String get incomeBreakdown => _t('Income Breakdown', 'आय विवरण',        'ఆదాయ వివరణ');
  String get savingsPot     => _t('Savings Pot',      'बचत पात्र',        'పొదుపు పాత్ర');

  // ── Transactions ──────────────────────────────────────────
  String get transactions   => _t('Transactions',     'लेनदेन',           'లావాదేవీలు');
  String get search         => _t('Search transactions...', 'लेनदेन खोजें...', 'లావాదేవీలు వెతకండి...');
  String get noTxnsFound    => _t('No transactions found', 'कोई लेनदेन नहीं मिला', 'లావాదేవీలు కనుగొనబడలేదు');
  String get today          => _t('Today',            'आज',               'ఈరోజు');
  String get yesterday      => _t('Yesterday',        'कल',               'నిన్న');

  // ── Add Expense ───────────────────────────────────────────
  String get addTransaction => _t('Add Transaction',  'लेनदेन जोड़ें',    'లావాదేవీ జోడించు');
  String get manual         => _t('Manual',           'मैन्युअल',         'మాన్యువల్');
  String get voice          => _t('Voice',            'आवाज़',            'వాయిస్');
  String get scan           => _t('Scan',             'स्कैन',            'స్కాన్');
  String get amount         => _t('Amount',           'राशि',             'మొత్తం');
  String get note           => _t('Note',             'नोट',              'గమనిక');
  String get category       => _t('Category',         'श्रेणी',           'వర్గం');
  String get date           => _t('Date',             'तारीख',            'తేదీ');
  String get saveExpense    => _t('Save Expense',     'खर्च सहेजें',      'ఖర్చు సేవ్ చేయి');
  String get saveIncome     => _t('Save Income',      'आय सहेजें',        'ఆదాయం సేవ్ చేయి');
  String get expense        => _t('Expense',          'खर्च',             'ఖర్చు');
  String get autoDetected   => _t('Auto-detected',    'स्वतः पहचाना',     'స్వయంచాలకంగా గుర్తించబడింది');

  // ── Goals ─────────────────────────────────────────────────
  String get myGoals        => _t('My Goals',         'मेरे लक्ष्य',      'నా లక్ష్యాలు');
  String get newGoal        => _t('New Goal',         'नया लक्ष्य',       'కొత్త లక్ష్యం');
  String get goalName       => _t('Goal Name',        'लक्ष्य नाम',       'లక్ష్యం పేరు');
  String get targetAmount   => _t('Target Amount',    'लक्ष्य राशि',      'లక్ష్య మొత్తం');
  String get deadline       => _t('Deadline',         'समय सीमा',         'గడువు');
  String get addMoney       => _t('Add Money',        'पैसे जोड़ें',      'డబ్బు జోడించు');
  String get saved          => _t('saved',            'बचाया',            'సేవ్ చేయబడింది');
  String get target         => _t('Target',           'लक्ष्य',           'లక్ష్యం');
  String get daysLeft       => _t('days left',        'दिन बाकी',         'రోజులు మిగిలాయి');
  String get goalAchieved   => _t('Goal Achieved!',   'लक्ष्य प्राप्त!',  'లక్ష్యం సాధించారు!');
  String get createGoal     => _t('Create Goal',      'लक्ष्य बनाएं',     'లక్ష్యం సృష్టించు');
  String get noGoalsYet     => _t('No goals yet',     'अभी कोई लक्ष्य नहीं', 'ఇంకా లక్ష్యాలు లేవు');

  // ── Savings ───────────────────────────────────────────────
  String get mySavings      => _t('My Savings',       'मेरी बचत',         'నా పొదుపు');
  String get totalSavings   => _t('Total Savings',    'कुल बचत',          'మొత్తం పొదుపు');
  String get deposit        => _t('Deposit',          'जमा करें',         'డిపాజిట్');
  String get withdraw       => _t('Withdraw',         'निकालें',          'విత్‌డ్రా');
  String get depositToSavings => _t('Deposit to Savings', 'बचत में जमा करें', 'పొదుపులో జమ చేయి');
  String get withdrawFromSavings => _t('Withdraw from Savings', 'बचत से निकालें', 'పొదుపు నుండి తీసుకో');
  String get savingsHistory => _t('Savings History',  'बचत इतिहास',       'పొదుపు చరిత్ర');
  String get addToBalance   => _t('Add to Balance',   'शेष में जोड़ें',   'బ్యాలెన్స్‌కు జోడించు');

  // ── Profile ───────────────────────────────────────────────
  String get profile        => _t('Profile',          'प्रोफ़ाइल',        'ప్రొఫైల్');
  String get settings       => _t('Settings',         'सेटिंग्स',         'సెట్టింగులు');
  String get darkMode       => _t('Dark Mode',        'डार्क मोड',        'డార్క్ మోడ్');
  String get language       => _t('Language',         'भाषा',             'భాష');
  String get currency       => _t('Currency',         'मुद्रा',           'కరెన్సీ');
  String get security       => _t('Security',         'सुरक्षा',          'భద్రత');
  String get pinLock        => _t('PIN Lock',         'पिन लॉक',          'పిన్ లాక్');
  String get fingerprint    => _t('Fingerprint / Face ID', 'फिंगरप्रिंट / फेस ID', 'వేలిముద్ర / ముఖ ID');
  String get cloudSync      => _t('Cloud Sync',       'क्लाउड सिंक',      'క్లౌడ్ సింక్');
  String get exportPdf      => _t('Export as PDF',    'PDF के रूप में निर्यात करें', 'PDF గా ఎగుమతి చేయి');
  String get achievements   => _t('Achievements & Gamification', 'उपलब्धियां और गेमिफिकेशन', 'విజయాలు మరియు గేమిఫికేషన్');
  String get splitExpenses  => _t('Split Expenses',   'खर्च विभाजित करें', 'ఖర్చులు విభజించు');
  String get activeMember   => _t('Active Member',    'सक्रिय सदस्य',     'యాక్టివ్ సభ్యుడు');
  String get editProfile    => _t('Edit Profile',     'प्रोफ़ाइल संपादित करें', 'ప్రొఫైల్ సవరించు');
  String get saveChanges    => _t('Save Changes',     'परिवर्तन सहेजें',  'మార్పులు సేవ్ చేయి');
  String get selectLanguage => _t('Select Language',  'भाषा चुनें',       'భాష ఎంచుకోండి');
  String get selectCurrency => _t('Select Currency',  'मुद्रा चुनें',     'కరెన్సీ ఎంచుకోండి');
  String get logoutConfirm  => _t('Are you sure you want to logout?', 'क्या आप लॉग आउट करना चाहते हैं?', 'మీరు లాగ్ అవుట్ చేయాలనుకుంటున్నారా?');

  // ── Setup ─────────────────────────────────────────────────
  String get monthlyIncome  => _t('Monthly Income',   'मासिक आय',         'నెలవారీ ఆదాయం');
  String get pocketMoney    => _t('Monthly Pocket Money', 'मासिक जेब खर्च', 'నెలవారీ జేబు డబ్బు');
  String get monthlyBudgetSetup => _t('Monthly Spending Budget', 'मासिक खर्च बजट', 'నెలవారీ వ్యయ బడ్జెట్');
  String get financialGoal  => _t('Financial Goal',   'वित्तीय लक्ष्य',   'ఆర్థిక లక్ష్యం');
  String get continueBtn    => _t('Continue',         'जारी रखें',        'కొనసాగించు');
  String get getStarted     => _t('Get Started',      'शुरू करें',        'ప్రారంభించు');
  String get student        => _t('Student',          'छात्र',            'విద్యార్థి');
  String get professional   => _t('Working Professional', 'कामकाजी पेशेवर', 'పని చేసే నిపుణుడు');

  // ── Gamification ──────────────────────────────────────────
  String get savingsScore   => _t('Savings Score',    'बचत स्कोर',        'పొదుపు స్కోర్');
  String get streak         => _t('Daily Tracking Streak', 'दैनिक ट्रैकिंग स्ट्रीक', 'రోజువారీ ట్రాకింగ్ స్ట్రీక్');
  String get badges         => _t('Badges',           'बैज',              'బ్యాడ్జ్‌లు');
  String get challenges     => _t('Active Challenges', 'सक्रिय चुनौतियां', 'యాక్టివ్ సవాళ్లు');
  String get themes         => _t('Themes',           'थीम',              'థీమ్‌లు');
  String get rewards        => _t('Rewards',          'पुरस्कार',         'బహుమతులు');
  String get unlocked       => _t('Unlocked',         'अनलॉक',            'అన్‌లాక్');

  // ── Analytics ─────────────────────────────────────────────
  String get analytics      => _t('Analytics',        'विश्लेषण',         'విశ్లేషణ');
  String get totalSpent     => _t('Total Spent',      'कुल खर्च',         'మొత్తం ఖర్చు');
  String get totalSaved2    => _t('Total Saved',      'कुल बचत',          'మొత్తం పొదుపు');
  String get spendingByCategory => _t('Spending by Category', 'श्रेणी के अनुसार खर्च', 'వర్గం వారీగా వ్యయం');
  String get spendingTrend  => _t('Spending Trend',   'खर्च प्रवृत्ति',   'వ్యయ ధోరణి');
  String get monthlyComparison => _t('Monthly Comparison', 'मासिक तुलना', 'నెలవారీ పోలిక');

  // ── Helper ────────────────────────────────────────────────
  String _t(String en, String hi, String te) {
    switch (languageCode) {
      case 'hi': return hi;
      case 'te': return te;
      default:   return en;
    }
  }
}

// Delegate so Flutter's Localizations widget can find AppLocalizations
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale.languageCode);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
