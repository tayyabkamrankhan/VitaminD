import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/uv_reading.dart';
import '../../../core/utils/date_utils.dart';

class CalendarHeatmap extends StatelessWidget {
  final List<UVSession> sessions;
  final int age;
  const CalendarHeatmap({super.key, required this.sessions, required this.age});

  double get _target => age > 70 ? 800 : age < 1 ? 400 : 600;

  Color _cellColor(double iu) {
    if (iu <= 0)              return AppColors.bgCardAlt;
    if (iu >= _target)        return AppColors.statusNormal;
    if (iu >= _target * 0.4) return AppColors.statusInsuff;
    return AppColors.statusDeficient;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final dayTotals = <int, double>{};
    for (final s in sessions) {
      if (s.date.month == today.month && s.date.year == today.year) {
        dayTotals[s.date.day] = (dayTotals[s.date.day] ?? 0) + s.synthesizedIU;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppDateUtils.formatMonth(today),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        // Weekday headers
        Row(children: ['S','M','T','W','T','F','S'].map((d) => Expanded(
          child: Center(child: Text(d,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10))),
        )).toList()),
        const SizedBox(height: 8),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, idx) {
            if (idx < startWeekday) return const SizedBox();
            final day = idx - startWeekday + 1;
            final iu  = dayTotals[day] ?? 0;
            final isToday = day == today.day;
            return Container(
              decoration: BoxDecoration(
                color: _cellColor(iu),
                borderRadius: BorderRadius.circular(4),
                border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
              ),
              child: Center(child: Text('$day',
                  style: TextStyle(fontSize: 9,
                      color: iu > 0 ? Colors.white : AppColors.textMuted))),
            );
          },
        ),
        const SizedBox(height: 12),
        // Legend
        Row(children: [
          _Legend(color: AppColors.statusNormal, label: 'Target met'),
          const SizedBox(width: 12),
          _Legend(color: AppColors.statusInsuff, label: 'Partial'),
          const SizedBox(width: 12),
          _Legend(color: AppColors.statusDeficient, label: 'Deficient'),
          const SizedBox(width: 12),
          _Legend(color: AppColors.bgCardAlt, label: 'No data'),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color; final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
  ]);
}
