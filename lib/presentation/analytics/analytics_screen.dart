import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/uv_data_provider.dart';
import '../../providers/social_provider.dart';
import 'widgets/trend_chart.dart';
import 'widgets/calendar_heatmap.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.profile != null) {
        context.read<UVDataProvider>().loadTodayData(auth.profile!.uid);
        context.read<SocialProvider>().loadAllAppUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uv   = context.watch<UVDataProvider>();
    final auth = context.watch<AuthProvider>();
    final social = context.watch<SocialProvider>();
    final age  = auth.profile?.age ?? 25;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Summary stats row
          _SummaryRow(
            weeklyAvg: _weeklyAvg(uv),
            bestDay: _bestDay(uv),
            streak: _calcStreak(uv),
          ),
          const SizedBox(height: 20),

          // 7-day trend chart
          const Text('7-Day Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          TrendChart(sessions: uv.weeklySessions, age: age),
          const SizedBox(height: 20),

          // Calendar heatmap
          const Text('Monthly Calendar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          CalendarHeatmap(sessions: uv.weeklySessions, age: age),
          const SizedBox(height: 20),

          // Supplement breakdown
          _SupplementBreakdown(
              supplements: uv.todaySupplements,
              synthesized: uv.synthesizedIU),
          const SizedBox(height: 25),

          // Live active users section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live App Active Users',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${social.allRegisteredUsers.length} Registered',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LiveActiveUsersCard(social: social),
        ]),
      ),
    );
  }

  double _weeklyAvg(UVDataProvider uv) {
    if (uv.weeklySessions.isEmpty) return 0;
    final total = uv.weeklySessions.fold(0.0, (s, e) => s + e.synthesizedIU);
    return total / 7;
  }

  double _bestDay(UVDataProvider uv) {
    if (uv.weeklySessions.isEmpty) return 0;
    return uv.weeklySessions
        .map((s) => s.synthesizedIU)
        .reduce((a, b) => a > b ? a : b);
  }

  int _calcStreak(UVDataProvider uv) {
    if (uv.weeklySessions.isEmpty) return 0;
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final hit = uv.weeklySessions.any((s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day &&
          s.synthesizedIU > 100);
      if (hit) streak++; else break;
    }
    return streak;
  }
}

class _SummaryRow extends StatelessWidget {
  final double weeklyAvg, bestDay;
  final int streak;
  const _SummaryRow({required this.weeklyAvg, required this.bestDay, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatCard(label: 'Weekly avg', value: '${weeklyAvg.round()} IU', icon: Icons.bar_chart, color: AppColors.primary),
      const SizedBox(width: 10),
      _StatCard(label: 'Best day', value: '${bestDay.round()} IU', icon: Icons.emoji_events_outlined, color: AppColors.sunYellow),
      const SizedBox(width: 10),
      _StatCard(label: 'Day streak', value: '$streak 🔥', icon: Icons.local_fire_department_outlined, color: AppColors.uvColor),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ]),
  ));
}

class _SupplementBreakdown extends StatelessWidget {
  final List supplements; final double synthesized;
  const _SupplementBreakdown({required this.supplements, required this.synthesized});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Today\'s Sources', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        _SourceRow(label: 'Sun synthesis', iu: synthesized, color: AppColors.sunYellow, icon: Icons.wb_sunny_outlined),
        const SizedBox(height: 10),
        ...supplements.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SourceRow(
            label: s.name as String,
            iu: s.dosageIU as double,
            color: s.type == 'supplement' ? AppColors.primary : AppColors.statusNormal,
            icon: s.type == 'supplement' ? Icons.medication_outlined : Icons.restaurant_outlined,
          ),
        )),
        if (supplements.isEmpty && synthesized == 0)
          const Text('No data logged today yet.',
              style: TextStyle(color: AppColors.textMuted)),
      ]),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String label; final double iu; final Color color; final IconData icon;
  const _SourceRow({required this.label, required this.iu, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(width: 10),
    Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
    Text('${iu.round()} IU', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
  ]);
}

class _LiveActiveUsersCard extends StatelessWidget {
  final SocialProvider social;
  const _LiveActiveUsersCard({required this.social});

  @override
  Widget build(BuildContext context) {
    if (social.loadingAllUsers) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final users = social.allRegisteredUsers;
    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Center(
          child: Text('No registered users found.', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final u = users[i];
          final progress = (u.todaySynthesized / u.dailyTarget).clamp(0.0, 1.0);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.bgHighlight,
              child: Text(
                u.name[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: progress >= 1.0 ? AppColors.statusNormal.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${u.todaySynthesized.round()} IU',
                    style: TextStyle(
                      color: progress >= 1.0 ? AppColors.statusNormal : AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(u.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(
                      progress >= 1.0 ? AppColors.statusNormal : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
