import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/uv_data_provider.dart';

class SupplementTracker extends StatefulWidget {
  const SupplementTracker({super.key});

  @override
  State<SupplementTracker> createState() => _SupplementTrackerState();
}

class _SupplementTrackerState extends State<SupplementTracker> {
  static const _quickSupplements = [
    {'name': 'Vitamin D3 400 IU',  'iu': 400.0,  'type': 'supplement'},
    {'name': 'Vitamin D3 1000 IU', 'iu': 1000.0, 'type': 'supplement'},
    {'name': 'Vitamin D3 2000 IU', 'iu': 2000.0, 'type': 'supplement'},
    {'name': 'Salmon (85g)',        'iu': 447.0,  'type': 'food'},
    {'name': 'Fortified milk (1c)', 'iu': 120.0,  'type': 'food'},
    {'name': 'Egg yolk',            'iu': 44.0,   'type': 'food'},
    {'name': 'Tuna (85g)',          'iu': 154.0,  'type': 'food'},
  ];

  Future<void> _log(Map item) async {
    final auth = context.read<AuthProvider>();
    final uv   = context.read<UVDataProvider>();
    if (auth.profile == null) return;
    await uv.addSupplement(auth.profile!.uid,
        item['name'] as String, item['iu'] as double, item['type'] as String);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${item['name']} logged — +${(item['iu'] as double).round()} IU'),
        backgroundColor: AppColors.statusNormalBg,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uv = context.watch<UVDataProvider>();
    final auth = context.read<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Today's total
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5)),
          child: Row(children: [
            const Icon(Icons.medication_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Today\'s supplement total',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('${(uv.supplementIU + uv.dietaryIU).round()} IU',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        const Text('Quick Log', style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Tap to add to today\'s intake',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 12),

        ..._quickSupplements.map((item) {
          final isFood = item['type'] == 'food';
          return GestureDetector(
            onTap: () => _log(item),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5)),
              child: Row(children: [
                Icon(isFood ? Icons.restaurant_outlined : Icons.medication_outlined,
                    color: isFood ? AppColors.statusNormal : AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['name'] as String,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  Text(isFood ? 'Dietary source' : 'Supplement',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ])),
                Text('+${(item['iu'] as double).round()} IU',
                    style: const TextStyle(color: AppColors.primary,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 8),
                const Icon(Icons.add_circle_outline, color: AppColors.textMuted, size: 18),
              ]),
            ),
          );
        }),

        const SizedBox(height: 20),
        // Today's log
        if (uv.todaySupplements.isNotEmpty) ...[
          const Text('Logged Today', style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...uv.todaySupplements.map((log) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.bgCardAlt,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(child: Text(log.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
              Text('+${log.dosageIU.round()} IU',
                  style: const TextStyle(color: AppColors.statusNormal,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  if (auth.profile != null) {
                    await uv.removeSupplement(auth.profile!.uid, log.id);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close, color: AppColors.textMuted, size: 16),
                ),
              ),
            ]),
          )),
        ],
      ]),
    );
  }
}
