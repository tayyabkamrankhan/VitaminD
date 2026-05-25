import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/symptom_log.dart';
import '../../../data/repositories/health_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/uv_data_provider.dart';

class SymptomChecker extends StatefulWidget {
  const SymptomChecker({super.key});

  @override
  State<SymptomChecker> createState() => _SymptomCheckerState();
}

class _SymptomCheckerState extends State<SymptomChecker> {
  final Set<String> _selected = {};
  int _severity = 2;
  bool _saved = false;

  String _buildRecommendation(UVDataProvider uv) {
    if (uv.totalIU < 240) {
      return 'Your Vitamin D is very low. The symptoms you selected are commonly linked to deficiency. Consider increasing sun exposure and consulting a physician about supplementation.';
    }
    if (_selected.contains('Bone pain') || _selected.contains('Muscle weakness')) {
      return 'Bone and muscle symptoms can indicate Vitamin D deficiency. Aim for 20 min of midday sun daily and consider a Vitamin D3 supplement (1000–2000 IU/day).';
    }
    if (_selected.contains('Fatigue') || _selected.contains('Brain fog')) {
      return 'Fatigue and brain fog are early signs of insufficiency. Try improving your morning sun routine and track your levels consistently.';
    }
    return 'Monitor your symptoms over the next week. Maintain your daily sun exposure routine and log any changes.';
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final uv   = context.read<UVDataProvider>();
    final repo = context.read<HealthRepository>();
    if (auth.profile == null) return;

    final log = repo.makeSymptomLog(
      userId: auth.profile!.uid,
      symptoms: _selected.toList(),
      severity: _severity,
      aiRecommendation: _buildRecommendation(uv),
    );
    await repo.logSymptoms(log);
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final uv = context.watch<UVDataProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How are you feeling today?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Select any symptoms you\'re experiencing',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),

        // Symptom chips
        Wrap(spacing: 10, runSpacing: 10,
          children: SymptomLog.allSymptoms.map((s) {
            final sel = _selected.contains(s);
            return FilterChip(
              label: Text(s),
              selected: sel,
              onSelected: (_) => setState(() =>
                  sel ? _selected.remove(s) : _selected.add(s)),
              selectedColor: AppColors.bgHighlight,
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.bgCard,
              labelStyle: TextStyle(
                  color: sel ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 13),
              side: BorderSide(
                  color: sel ? AppColors.primary : AppColors.border,
                  width: sel ? 1.5 : 0.5),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Severity slider
        const Text('Severity', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Row(children: [
          const Text('Mild', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Expanded(child: Slider(
            value: _severity.toDouble(), min: 1, max: 5, divisions: 4,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _severity = v.round()),
          )),
          const Text('Severe', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 20),

        // AI recommendation
        if (_selected.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1060),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3A2A6A), width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.auto_awesome, color: AppColors.aiPurple, size: 14),
                SizedBox(width: 6),
                Text('AI RECOMMENDATION', style: TextStyle(color: AppColors.aiPurple,
                    fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ]),
              const SizedBox(height: 8),
              Text(_buildRecommendation(uv),
                  style: const TextStyle(color: Color(0xFFC4C4E0),
                      fontSize: 13, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        ElevatedButton(
          onPressed: _selected.isEmpty || _saved ? null : _save,
          child: Text(_saved ? '✓ Saved' : 'Log Symptoms'),
        ),
        if (_saved)
          const Padding(padding: EdgeInsets.only(top: 8),
            child: Text('Symptoms logged successfully.',
                style: TextStyle(color: AppColors.statusNormal, fontSize: 13))),
      ]),
    );
  }
}
