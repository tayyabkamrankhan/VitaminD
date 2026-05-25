import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';

class LiveUVGraph extends StatefulWidget {
  final double currentUVIndex;
  const LiveUVGraph({super.key, required this.currentUVIndex});

  @override
  State<LiveUVGraph> createState() => _LiveUVGraphState();
}

class _LiveUVGraphState extends State<LiveUVGraph> {
  final List<FlSpot> _points = [];
  int _tick = 0;

  @override
  void didUpdateWidget(LiveUVGraph old) {
    super.didUpdateWidget(old);
    if (old.currentUVIndex != widget.currentUVIndex) {
      setState(() {
        _points.add(FlSpot(_tick.toDouble(), widget.currentUVIndex));
        if (_points.length > 60) _points.removeAt(0); // keep last 60 readings
        _tick++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _points.isEmpty
        ? [FlSpot(0, 0)]
        : _points;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('LIVE UV GRAPH',
            style: TextStyle(color: AppColors.textMuted,
                fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Expanded(child: LineChart(LineChartData(
          minY: 0, maxY: 12,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 3,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.border, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28, interval: 3,
              getTitlesWidget: (v, _) => Text(v.round().toString(),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
            )),
            rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withOpacity(0.1),
            ),
          )],
        ))),
      ]),
    );
  }
}
