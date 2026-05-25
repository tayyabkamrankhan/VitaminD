import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/uv_reading.dart';
import '../../../core/utils/date_utils.dart';

class TrendChart extends StatelessWidget {
  final List<UVSession> sessions;
  final int age;
  const TrendChart({super.key, required this.sessions, required this.age});

  double get _target => age > 70 ? 800 : age < 1 ? 400 : 600;

  @override
  Widget build(BuildContext context) {
    final days = AppDateUtils.lastNDays(7);
    final spots = days.asMap().entries.map((e) {
      final dayTotal = sessions
          .where((s) => AppDateUtils.isSameDay(s.date, e.value))
          .fold(0.0, (sum, s) => sum + s.synthesizedIU);
      return FlSpot(e.key.toDouble(), dayTotal);
    }).toList();

    final targetSpots = [FlSpot(0, _target), FlSpot(6, _target)];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: LineChart(LineChartData(
        minY: 0, maxY: (_target * 1.3).ceilToDouble(),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          horizontalInterval: _target / 2,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 36, interval: _target / 2,
            getTitlesWidget: (v, _) => Text('${v.round()}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
          )),
          rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 22,
            getTitlesWidget: (v, _) {
              final idx = v.round();
              if (idx < 0 || idx >= days.length) return const SizedBox();
              return Text(AppDateUtils.weekdayShort(days[idx])[0],
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
            },
          )),
        ),
        lineBarsData: [
          // Actual IU line
          LineChartBarData(
            spots: spots, isCurved: true,
            color: AppColors.primary, barWidth: 2.5,
            dotData: FlDotData(getDotPainter: (s, _, __, ___) =>
                FlDotCirclePainter(radius: 3, color: AppColors.primary,
                    strokeColor: AppColors.bgCard, strokeWidth: 1.5)),
            belowBarData: BarAreaData(show: true,
                color: AppColors.primary.withOpacity(0.1)),
          ),
          // Target line (dashed)
          LineChartBarData(
            spots: targetSpots, isCurved: false,
            color: AppColors.statusNormal.withOpacity(0.5),
            barWidth: 1, dashArray: [6, 4],
            dotData: FlDotData(show: false),
          ),
        ],
      )),
    );
  }
}
