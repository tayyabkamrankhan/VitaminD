import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DailySummaryCard extends StatelessWidget {
  final double uvIndex, sessionMinutes, synthesizedIU, supplementIU;
  const DailySummaryCard({super.key,
    required this.uvIndex, required this.sessionMinutes,
    required this.synthesizedIU, required this.supplementIU});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        _Tile(icon: Icons.wb_sunny_outlined, color: AppColors.sunYellow,
            label: 'UV index', value: uvIndex.toStringAsFixed(1)),
        _divider(),
        _Tile(icon: Icons.timer_outlined, color: AppColors.accent,
            label: 'Exposure', value: '${sessionMinutes.round()} min'),
        _divider(),
        _Tile(icon: Icons.flash_on_outlined, color: AppColors.primary,
            label: 'Synthesised', value: '${synthesizedIU.round()} IU'),
        _divider(),
        _Tile(icon: Icons.medication_outlined, color: AppColors.statusNormal,
            label: 'Supplements', value: '${supplementIU.round()} IU'),
      ]),
    );
  }

  Widget _divider() => Container(
      width: 0.5, height: 40, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _Tile extends StatelessWidget {
  final IconData icon; final Color color;
  final String label, value;
  const _Tile({required this.icon, required this.color,
      required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Icon(icon, color: color, size: 18),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
        textAlign: TextAlign.center),
  ]));
}
