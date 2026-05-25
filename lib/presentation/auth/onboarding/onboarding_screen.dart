import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../../providers/providers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form values
  int _age = 25;
  String _gender = 'male';
  int _skinTone = 5;
  double _weight = 70;
  String _city = 'Lahore';

  void _next() {
    if (_currentPage < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _save();
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final updated = auth.profile!.copyWith(
      age: _age, gender: _gender, skinTone: _skinTone,
      weightKg: _weight, city: _city,
    );
    await auth.updateProfile(updated);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(children: List.generate(4, (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _currentPage
                      ? AppColors.primary : AppColors.bgCardAlt,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ))),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _AgeGenderStep(age: _age, gender: _gender,
                    onAge: (v) => setState(() => _age = v),
                    onGender: (v) => setState(() => _gender = v)),
                _SkinToneStep(skinTone: _skinTone,
                    onChanged: (v) => setState(() => _skinTone = v)),
                _WeightStep(weight: _weight,
                    onChanged: (v) => setState(() => _weight = v)),
                _CityStep(city: _city,
                    onChanged: (v) => setState(() => _city = v)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prev,
                    child: const Text('Back'),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_currentPage == 3 ? 'Get Started' : 'Continue'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Step 1: Age & Gender ──────────────────────────────────────────────────────

class _AgeGenderStep extends StatelessWidget {
  final int age; final String gender;
  final void Function(int) onAge; final void Function(String) onGender;
  const _AgeGenderStep({required this.age, required this.gender,
      required this.onAge, required this.onGender});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
        Text('Tell us about yourself',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Used to calculate your personalised vitamin D target',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 40),

        Text('Age: $age years',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        Slider(
          value: age.toDouble(), min: 1, max: 90, divisions: 89,
          activeColor: AppColors.primary,
          onChanged: (v) => onAge(v.round()),
        ),
        const SizedBox(height: 32),

        const Text('Gender', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Row(children: ['male', 'female', 'other'].map((g) {
          final selected = gender == g;
          return Expanded(child: GestureDetector(
            onTap: () => onGender(g),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.bgHighlight : AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 0.5,
                ),
              ),
              child: Center(child: Text(
                g[0].toUpperCase() + g.substring(1),
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              )),
            ),
          ));
        }).toList()),
      ]),
    ));
  }
}

// ── Step 2: Skin Tone ─────────────────────────────────────────────────────────

class _SkinToneStep extends StatelessWidget {
  final int skinTone; final void Function(int) onChanged;
  const _SkinToneStep({required this.skinTone, required this.onChanged});

  static const _tones = [
    {'label': 'Type I', 'desc': 'Very fair', 'color': Color(0xFFF5CBA7)},
    {'label': 'Type II', 'desc': 'Fair', 'color': Color(0xFFE8A87C)},
    {'label': 'Type III', 'desc': 'Medium', 'color': Color(0xFFD4845A)},
    {'label': 'Type IV', 'desc': 'Olive', 'color': Color(0xFFB5622A)},
    {'label': 'Type V', 'desc': 'Brown', 'color': Color(0xFF8B4513)},
    {'label': 'Type VI', 'desc': 'Dark', 'color': Color(0xFF4A2508)},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
        Text('Your skin tone', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Darker skin tones require longer sun exposure to synthesise the same amount of Vitamin D',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bgHighlight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '💡 Your Arduino watch will auto-detect this via its colour sensor — you can update manually here.',
            style: TextStyle(color: AppColors.aiPurple, fontSize: 12),
          ),
        ),
        const SizedBox(height: 32),
        GridView.count(
          shrinkWrap: true, crossAxisCount: 3,
          mainAxisSpacing: 12, crossAxisSpacing: 12,
          children: List.generate(6, (i) {
            final t = _tones[i];
            final selected = skinTone == i + 1;
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 2 : 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: t['color'] as Color,
                          shape: BoxShape.circle,
                        )),
                    const SizedBox(height: 8),
                    Text(t['label'] as String,
                        style: const TextStyle(fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500)),
                    Text(t['desc'] as String,
                        style: const TextStyle(fontSize: 10,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }),
        ),
      ]),
    ));
  }
}

// ── Step 3: Weight ────────────────────────────────────────────────────────────

class _WeightStep extends StatelessWidget {
  final double weight; final void Function(double) onChanged;
  const _WeightStep({required this.weight, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
        Text('Your weight', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Helps calibrate your body surface area for more accurate synthesis calculations',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 48),
        Center(child: Text('${weight.round()} kg',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700,
                color: AppColors.primary))),
        const SizedBox(height: 24),
        Slider(
          value: weight, min: 20, max: 160, divisions: 140,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
        const Center(child: Text('20 kg ← slide → 160 kg',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
      ]),
    ));
  }
}

// ── Step 4: City ──────────────────────────────────────────────────────────────

class _CityStep extends StatelessWidget {
  final String city; final void Function(String) onChanged;
  const _CityStep({required this.city, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cities = AppConstants.cityUVProfile.keys.toList()..sort();
    final currentCity = cities.contains(city) ? city : cities.first;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
        Text('Your city', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Each city has a unique UV profile and seasonal calendar',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 48),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentCity,
              isExpanded: true,
              dropdownColor: AppColors.bgCard,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
              items: cities.map((c) {
                final uv = AppConstants.cityUVProfile[c]!;
                return DropdownMenuItem(
                  value: c,
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(c, style: const TextStyle(color: AppColors.textPrimary))),
                    Text('UV avg ${uv.toStringAsFixed(1)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ]),
    ));
  }
}
