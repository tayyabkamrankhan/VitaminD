import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ClothingSelector extends StatelessWidget {
  final double current;
  final void Function(double) onChanged;

  const ClothingSelector({super.key, required this.current, required this.onChanged});

  static const _options = [
    {'label': 'Fully Exposed', 'sub': 'Arms + legs', 'icon': Icons.person_outline, 'value': 1.0},
    {'label': 'Half Exposed',  'sub': 'Arms only',   'icon': Icons.person,          'value': 0.5},
    {'label': 'Minimal',       'sub': 'Face + hands', 'icon': Icons.accessibility_new,'value': 0.2},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Clothing Coverage',
          style: TextStyle(color: AppColors.textSecondary,
              fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      Row(children: _options.map((o) {
        final sel = (o['value'] as double) == current;
        return Expanded(child: GestureDetector(
          onTap: () => onChanged(o['value'] as double),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: sel ? AppColors.bgHighlight : AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: sel ? AppColors.primary : AppColors.border,
                  width: sel ? 1.5 : 0.5),
            ),
            child: Column(children: [
              Icon(o['icon'] as IconData,
                  color: sel ? AppColors.primary : AppColors.textMuted, size: 22),
              const SizedBox(height: 6),
              Text(o['label'] as String,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                      color: sel ? AppColors.primary : AppColors.textMuted),
                  textAlign: TextAlign.center),
              Text(o['sub'] as String,
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                  textAlign: TextAlign.center),
            ]),
          ),
        ));
      }).toList()),
    ]);
  }
}
