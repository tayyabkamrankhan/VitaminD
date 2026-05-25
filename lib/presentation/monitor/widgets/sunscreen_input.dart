import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SunscreenInput extends StatelessWidget {
  final int currentSpf;
  final void Function(int) onChanged;

  const SunscreenInput({super.key, required this.currentSpf, required this.onChanged});

  static const _spfOptions = [0, 15, 30, 50, 100];

  String _label(int spf) => spf == 0 ? 'None' : 'SPF $spf';

  String _description(int spf) {
    if (spf == 0)   return 'No sunscreen';
    if (spf <= 15)  return 'Low protection';
    if (spf <= 30)  return 'Medium';
    if (spf <= 50)  return 'High protection';
    return 'Very high';
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Sunscreen SPF',
            style: TextStyle(color: AppColors.textSecondary,
                fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        if (currentSpf > 0)
          Text('Blocks ~${_blockPercent(currentSpf)}% UVB',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
      const SizedBox(height: 10),
      Row(children: _spfOptions.map((spf) {
        final sel = spf == currentSpf;
        return Expanded(child: GestureDetector(
          onTap: () => onChanged(spf),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel ? AppColors.bgHighlight : AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: sel ? AppColors.primary : AppColors.border,
                  width: sel ? 1.5 : 0.5),
            ),
            child: Column(children: [
              Text(_label(spf),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: sel ? AppColors.primary : AppColors.textMuted)),
              Text(_description(spf),
                  style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
                  textAlign: TextAlign.center),
            ]),
          ),
        ));
      }).toList()),
    ]);
  }

  String _blockPercent(int spf) => ((1 - 1 / spf) * 100).round().toString();
}
