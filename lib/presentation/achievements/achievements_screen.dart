import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/uv_data_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uv = context.watch<UVDataProvider>();
    final badges = _buildBadges(uv);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Streak section
          _StreakCard(streak: _calcStreak(uv)),
          const SizedBox(height: 20),

          // Badges
          const Text('Badges', style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12, crossAxisSpacing: 12,
            children: badges.map((b) => _BadgeTile(badge: b)).toList(),
          ),
          const SizedBox(height: 20),

          // Weekly challenge
          _WeeklyChallenge(sessions: uv.weeklySessions),
        ]),
      ),
    );
  }

  int _calcStreak(UVDataProvider uv) {
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      final hit = uv.weeklySessions.any((s) =>
          s.date.year == day.year && s.date.month == day.month &&
          s.date.day == day.day && s.synthesizedIU > 50);
      if (hit) streak++; else break;
    }
    return streak;
  }

  List<_Badge> _buildBadges(UVDataProvider uv) {
    final totalSessions = uv.weeklySessions.length;
    final streak        = _calcStreak(uv);
    final totalIU       = uv.totalIU;

    return [
      _Badge('First Step',    '🌱', 'Log your first session',   totalSessions >= 1),
      _Badge('Sun Chaser',    '☀️', 'Complete 7 sessions',      totalSessions >= 7),
      _Badge('On Streak',     '🔥', 'Reach a 3-day streak',     streak >= 3),
      _Badge('Week Warrior',  '⚡', 'Reach a 7-day streak',     streak >= 7),
      _Badge('Target Hit',    '🎯', 'Hit daily target once',    totalIU >= 600),
      _Badge('Supplement Pro','💊', 'Log a supplement',         uv.supplementIU > 0),
      _Badge('Bone Builder',  '🦴', 'Reach 1000 IU in a day',  totalIU >= 1000),
      _Badge('South Asian',   '🇵🇰', 'Calibrated for your skin', true),
      _Badge('Month Strong',  '📅', '30-day streak',             streak >= 30),
    ];
  }
}

class _Badge {
  final String name, emoji, description;
  final bool unlocked;
  const _Badge(this.name, this.emoji, this.description, this.unlocked);
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.bgCard, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Row(children: [
      const Text('🔥', style: TextStyle(fontSize: 40)),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$streak', style: const TextStyle(
            fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const Text('Day streak', style: TextStyle(color: AppColors.textSecondary)),
        Text(streak == 0 ? 'Start today!' : 'Keep it up!',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ]),
    ]),
  );
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: badge.unlocked ? AppColors.bgHighlight : AppColors.bgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: badge.unlocked ? AppColors.primary : AppColors.border,
          width: badge.unlocked ? 1.5 : 0.5),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(badge.emoji,
          style: TextStyle(fontSize: 28,
              color: badge.unlocked ? null : Colors.transparent)),
      if (!badge.unlocked) const Icon(Icons.lock_outline,
          color: AppColors.textMuted, size: 22),
      const SizedBox(height: 6),
      Text(badge.name,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: badge.unlocked ? AppColors.primary : AppColors.textMuted),
          textAlign: TextAlign.center),
    ]),
  );
}

class _WeeklyChallenge extends StatelessWidget {
  final List sessions;
  const _WeeklyChallenge({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final daysHit = sessions.length.clamp(0, 7);
    final progress = daysHit / 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Weekly Challenge', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Hit your Vitamin D target 5 out of 7 days',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 14),
        Row(children: List.generate(7, (i) => Expanded(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 8,
          decoration: BoxDecoration(
            color: i < daysHit ? AppColors.primary : AppColors.bgCardAlt,
            borderRadius: BorderRadius.circular(4),
          ),
        )))),
        const SizedBox(height: 8),
        Text('$daysHit / 7 days complete',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
