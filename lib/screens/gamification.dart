import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/expense_provider.dart';
import '../services/gamification_service.dart';
import '../services/theme_service.dart';
import '../services/user_service.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});
  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  static IconData _challengeIcon(String key) {
    switch (key) {
      case 'restaurant': return Icons.restaurant_rounded;
      case 'movie':      return Icons.movie_rounded;
      case 'shield':     return Icons.shield_rounded;
      case 'fire':       return Icons.local_fire_department_rounded;
      case 'savings':    return Icons.savings_rounded;
      default:           return Icons.star_rounded;
    }
  }

  static IconData _badgeIcon(String key) {
    switch (key) {
      case 'wallet':  return Icons.account_balance_wallet_rounded;
      case 'savings': return Icons.savings_rounded;
      case 'star':    return Icons.star_rounded;
      case 'shield':  return Icons.shield_rounded;
      case 'fire':    return Icons.local_fire_department_rounded;
      case 'trophy':  return Icons.emoji_events_rounded;
      case 'check':   return Icons.check_circle_rounded;
      case 'chart':   return Icons.pie_chart_rounded;
      case 'hundred': return Icons.looks_one_rounded;
      default:        return Icons.military_tech_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final expenses      = provider.expenses;
        final score         = GamificationService.savingsScore(expenses);
        final scoreLabel    = GamificationService.scoreLabel(score);
        final streak        = GamificationService.streak;
        final bestStreak    = GamificationService.bestStreak;
        final badges        = GamificationService.badges(expenses);
        final challenges    = GamificationService.challenges(expenses);
        final unlockedCount = badges.where((b) => b.unlocked).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('Achievements',
                style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _scoreCard(score, scoreLabel, unlockedCount, badges.length),
              const SizedBox(height: 16),
              _streakCard(streak, bestStreak),
              const SizedBox(height: 20),
              _sectionHeader('Active Challenges',
                  '${challenges.where((c) => c.completed).length}/${challenges.length} done'),
              const SizedBox(height: 12),
              ...challenges.map((c) => _challengeCard(c)),
              const SizedBox(height: 20),
              _sectionHeader('Badges', '$unlockedCount/${badges.length} unlocked'),
              const SizedBox(height: 12),
              _badgesGrid(badges),
              const SizedBox(height: 20),
              _sectionHeader('Themes',
                  '${ThemeService.themes.where((t) => ThemeService.isUnlocked(t, unlockedCount)).length}/${ThemeService.themes.length} unlocked'),
              const SizedBox(height: 4),
              Text('Earn badges to unlock new app themes',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 12),
              _themesSection(unlockedCount),
              const SizedBox(height: 20),
              _sectionHeader('Rewards', 'Unlock by earning badges'),
              const SizedBox(height: 12),
              _rewardsSection(unlockedCount, badges.length),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Score Card ────────────────────────────────────────────
  Widget _scoreCard(int score, String label, int unlocked, int total) {
    final color = score >= 70
        ? Theme.of(context).colorScheme.primary
        : score >= 40
            ? const Color(0xFFFF6D00)
            : const Color(0xFFFF5252);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90, height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90, height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$score', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    Text('/100', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Savings Score', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$unlocked of $total badges unlocked',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? unlocked / total : 0,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Streak Card ───────────────────────────────────────────
  Widget _streakCard(int streak, int best) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFFF5252)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Tracking Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  streak == 0 ? 'Add an expense today to start your streak!' : 'Best: $best days — keep going!',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$streak', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF6D00))),
              Text('days', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Challenge Card ────────────────────────────────────────
  Widget _challengeCard(Challenge c) {
    final color    = Color(c.color);
    final currency = UserService.currency;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: c.completed ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: c.completed ? color : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_challengeIcon(c.icon), color: c.completed ? Colors.white : color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (c.completed) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('Done!', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Text(c.desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                c.isLower
                    ? '$currency${c.current.toStringAsFixed(0)} / $currency${c.target.toStringAsFixed(0)}'
                    : '${c.current.toStringAsFixed(0)} / ${c.target.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: c.progress,
              minHeight: 7,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(c.progress * 100).toInt()}% complete',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Badges Grid ───────────────────────────────────────────
  Widget _badgesGrid(List<AchievementBadge> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (_, i) {
        final b     = badges[i];
        final color = Color(b.color);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: b.unlocked ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5) : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: b.unlocked ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(_badgeIcon(b.icon), color: b.unlocked ? color : Colors.grey.shade400, size: 26),
              ),
              const SizedBox(height: 8),
              Text(b.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: b.unlocked ? Colors.black87 : Colors.grey)),
              const SizedBox(height: 3),
              Text(b.desc,
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
              const SizedBox(height: 4),
              b.unlocked
                  ? Icon(Icons.verified_rounded, color: color, size: 14)
                  : Icon(Icons.lock_outline_rounded, color: Colors.grey.shade300, size: 14),
            ],
          ),
        );
      },
    );
  }

  // ── Themes Section ────────────────────────────────────────
  Widget _themesSection(int unlockedBadges) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: activeThemeNotifier,
      builder: (ctx, currentTheme, _) {
        return Column(
          children: ThemeService.themes.map((theme) {
            final isUnlocked = ThemeService.isUnlocked(theme, unlockedBadges);
            final isActive   = theme.id == currentTheme.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isActive
                    ? Border.all(color: theme.primary, width: 2)
                    : isUnlocked
                        ? Border.all(color: theme.primary.withValues(alpha: 0.3))
                        : null,
                boxShadow: [
                  BoxShadow(
                    color: isActive ? theme.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: isActive ? 12 : 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUnlocked
                              ? theme.gradientColors
                              : [Colors.grey.shade300, Colors.grey.shade200],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: isUnlocked ? LinearGradient(colors: theme.gradientColors) : null,
                            color: isUnlocked ? null : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(theme.icon,
                              color: isUnlocked ? Colors.white : Colors.grey.shade400, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(theme.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isUnlocked ? Colors.black87 : Colors.grey)),
                                  if (isActive) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Active',
                                          style: TextStyle(color: theme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(theme.desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                isUnlocked
                                    ? (theme.badgesRequired == 0 ? 'Default theme' : 'Unlocked at ${theme.badgesRequired} badges')
                                    : theme.unlockRequirement,
                                style: TextStyle(
                                    color: isUnlocked ? theme.primary : Colors.grey.shade400,
                                    fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isUnlocked && !isActive)
                          GestureDetector(
                            onTap: () async {
                              await ThemeService.setTheme(theme.id);
                              activeThemeNotifier.value = theme;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${theme.name} theme applied!'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: theme.primary,
                                ));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: theme.gradientColors),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          )
                        else if (isActive)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(Icons.check_circle_rounded, color: theme.primary, size: 20),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 20),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Rewards Section ───────────────────────────────────────
  Widget _rewardsSection(int unlocked, int totalBadges) {
    final allUnlocked = unlocked >= totalBadges;
    final rewards = [
      _Reward('Starter Pack',   'Unlock 1 badge',    Icons.card_giftcard_rounded, Theme.of(context).colorScheme.primary, unlocked >= 1),
      _Reward('Ocean Theme',    'Unlock 1 badge',    Icons.water_rounded,          const Color(0xFF1565C0), unlocked >= 1),
      _Reward('Sunset Theme',   'Unlock 3 badges',   Icons.wb_sunny_rounded,       const Color(0xFFE64A19), unlocked >= 3),
      _Reward('Royal Theme',    'Unlock 5 badges',   Icons.auto_awesome_rounded,   const Color(0xFF6A1B9A), unlocked >= 5),
      _Reward('Midnight Theme', 'Unlock 7 badges',   Icons.nights_stay_rounded,    const Color(0xFFFFD700), unlocked >= 7),
      _Reward('Rose Gold Theme','Unlock all badges', Icons.workspace_premium_rounded, const Color(0xFFAD1457), unlocked >= 10),
    ];

    return Column(
      children: [
        if (allUnlocked) ...[
          _hallOfFameBanner(),
          const SizedBox(height: 16),
        ],
        ...rewards.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: r.unlocked ? Border.all(color: r.color.withValues(alpha: 0.4), width: 1.5) : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: r.unlocked ? r.color.withValues(alpha: 0.12) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(r.icon, color: r.unlocked ? r.color : Colors.grey.shade400, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                            color: r.unlocked ? Colors.black87 : Colors.grey)),
                    Text(r.requirement, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              r.unlocked
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: r.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text('Unlocked', style: TextStyle(color: r.color, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  : Icon(Icons.lock_outline_rounded, color: Colors.grey.shade300, size: 20),
            ],
          ),
        )),
      ],
    );
  }

  // ── Hall of Fame ──────────────────────────────────────────
  Widget _hallOfFameBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF6D00)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text('Finance Master!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text('You have unlocked every reward and mastered your finances!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (_) =>
                const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.star_rounded, color: Colors.white, size: 22))),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: const Text('Hall of Fame Member',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ],
    );
  }
}

class _Reward {
  final String title, requirement;
  final IconData icon;
  final Color color;
  final bool unlocked;
  const _Reward(this.title, this.requirement, this.icon, this.color, this.unlocked);
}

