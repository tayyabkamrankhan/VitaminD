import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/vitamin_d_calculator.dart';
import '../../../data/models/uv_reading.dart';
import '../../../providers/weather_provider.dart';
import '../../../providers/auth_provider.dart';

// ─── VitD Ring Widget ────────────────────────────────────────────────────────

class VitDRingWidget extends StatefulWidget {
  final double totalIU, synthesizedIU, supplementIU, progressRatio;
  final VitaminDStatus status;
  final int age;

  const VitDRingWidget({
    super.key,
    required this.totalIU,
    required this.synthesizedIU,
    required this.supplementIU,
    required this.status,
    required this.progressRatio,
    required this.age,
  });

  @override
  State<VitDRingWidget> createState() => _VitDRingWidgetState();
}

class _VitDRingWidgetState extends State<VitDRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween(begin: 0.0, end: widget.progressRatio)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(VitDRingWidget old) {
    super.didUpdateWidget(old);
    if (old.progressRatio != widget.progressRatio) {
      _anim = Tween(begin: _prev, end: widget.progressRatio)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
    _prev = widget.progressRatio;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _ringColor {
    switch (widget.status) {
      case VitaminDStatus.normal:       return AppColors.statusNormal;
      case VitaminDStatus.insufficient: return AppColors.statusInsuff;
      case VitaminDStatus.deficient:    return AppColors.statusDeficient;
      case VitaminDStatus.toxic:        return AppColors.statusToxic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Center(
        child: SizedBox(
          width: 220, height: 220,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(220, 220),
              painter: _RingPainter(ratio: _anim.value, color: _ringColor),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                '${widget.totalIU.round()}',
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const Text('IU today',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              _StatusBadge(status: widget.status),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Ring painter (simple, no factory) ────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double ratio;
  final Color color;

  const _RingPainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.width - sw) / 2;

    // Track
    canvas.drawCircle(
      center, r,
      Paint()
        ..color = AppColors.bgCardAlt
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * ratio.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ratio != ratio || old.color != color;
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final VitaminDStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    switch (status) {
      case VitaminDStatus.normal:
        bg = AppColors.statusNormalBg;    fg = AppColors.statusNormal;
      case VitaminDStatus.insufficient:
        bg = AppColors.statusInsuffBg;    fg = AppColors.statusInsuff;
      case VitaminDStatus.deficient:
        bg = AppColors.statusDeficientBg; fg = AppColors.statusDeficient;
      case VitaminDStatus.toxic:
        bg = AppColors.statusToxicBg;     fg = AppColors.statusToxic;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        VitaminDCalculator.statusLabel(status),
        style: TextStyle(
            color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── Daily Summary Card ───────────────────────────────────────────────────────

class DailySummaryCard extends StatelessWidget {
  final double uvIndex, sessionMinutes, synthesizedIU, supplementIU;

  const DailySummaryCard({
    super.key,
    required this.uvIndex,
    required this.sessionMinutes,
    required this.synthesizedIU,
    required this.supplementIU,
  });

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
        _StatTile(icon: Icons.wb_sunny_outlined,   color: AppColors.sunYellow,
            label: 'UV index',    value: uvIndex.toStringAsFixed(1)),
        _divider(),
        _StatTile(icon: Icons.timer_outlined,       color: AppColors.accent,
            label: 'Exposure',    value: '${sessionMinutes.round()} min'),
        _divider(),
        _StatTile(icon: Icons.flash_on_outlined,    color: AppColors.primary,
            label: 'Synthesised', value: '${synthesizedIU.round()} IU'),
        _divider(),
        _StatTile(icon: Icons.medication_outlined,  color: AppColors.statusNormal,
            label: 'Supplements', value: '${supplementIU.round()} IU'),
      ]),
    );
  }

  Widget _divider() => Container(
      width: 0.5, height: 40, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      Text(label,
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
          textAlign: TextAlign.center),
    ]),
  );
}

// ─── Weather Card Widget ──────────────────────────────────────────────────────

class WeatherCardWidget extends StatefulWidget {
  const WeatherCardWidget({super.key});

  @override
  State<WeatherCardWidget> createState() => _WeatherCardWidgetState();
}

class _WeatherCardWidgetState extends State<WeatherCardWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final city = context.read<AuthProvider>().profile?.city;
      context.read<WeatherProvider>().fetchWeather(city);
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = context.watch<WeatherProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: w.loading
          ? const Center(
          child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)))
          : w.error != null
          ? Row(children: [
        const Icon(Icons.wifi_off_rounded,
            color: AppColors.textMuted, size: 20),
        const SizedBox(width: 10),
        const Expanded(child: Text('Weather unavailable',
            style: TextStyle(color: AppColors.textMuted))),
        TextButton(
            onPressed: () {
              final city = context.read<AuthProvider>().profile?.city;
              w.fetchWeather(city);
            },
            child: const Text('Retry')),
      ])
          : Row(children: [
        Icon(_weatherIcon(w.weather?.condition ?? ''),
            color: AppColors.sunYellow, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.weather?.cityName ?? '—',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
            Text(
              '${w.weather?.condition ?? ''} · '
                  '${w.weather?.temperatureC.round() ?? '—'}°C'
                  '${w.bestWindow != null ? ' · Best window ${w.bestWindow}' : ''}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        )),
        Column(children: [
          Text(w.uvIndex.toStringAsFixed(1),
              style: const TextStyle(
                  color: AppColors.uvColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const Text('UV index',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 10)),
        ]),
      ]),
    );
  }

  IconData _weatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':        return Icons.wb_sunny_rounded;
      case 'clouds':       return Icons.cloud_rounded;
      case 'rain':
      case 'drizzle':      return Icons.grain_rounded;
      case 'thunderstorm': return Icons.thunderstorm_rounded;
      case 'snow':         return Icons.ac_unit_rounded;
      default:             return Icons.wb_sunny_rounded;
    }
  }
}

// ─── Weekly Bar Chart ─────────────────────────────────────────────────────────

class WeeklyBarChart extends StatelessWidget {
  final List<UVSession> sessions;
  final int age;

  const WeeklyBarChart({super.key, required this.sessions, required this.age});

  double get _target => age > 70 ? 800 : age < 1 ? 400 : 600;

  @override
  Widget build(BuildContext context) {
    final days = _buildDayTotals();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('This week',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 15)),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((d) {
            final iu     = d['iu'] as double;
            final ratio  = (iu / _target).clamp(0.0, 1.0);
            final color  = iu >= _target * 0.75
                ? AppColors.statusNormal
                : iu >= _target * 0.4
                ? AppColors.statusInsuff
                : AppColors.statusDeficient;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(children: [
                Text('${iu.round()}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 9)),
                const SizedBox(height: 4),
                Container(
                  height: 80 * ratio + 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(d['label'] as String,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
              ]),
            ));
          }).toList(),
        ),
      ]),
    );
  }

  List<Map<String, dynamic>> _buildDayTotals() {
    final now = DateTime.now();
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final total = sessions
          .where((s) =>
      s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day)
          .fold(0.0, (sum, s) => sum + s.synthesizedIU);
      return {'label': labels[day.weekday % 7], 'iu': total};
    });
  }
}

// ─── AI Tip Card ──────────────────────────────────────────────────────────────

class AiTipCard extends StatelessWidget {
  final double uvIndex, totalIU;
  final VitaminDStatus status;
  final String city;
  final int age;

  const AiTipCard({
    super.key,
    required this.uvIndex,
    required this.totalIU,
    required this.status,
    required this.city,
    required this.age,
  });

  String get _tip {
    final month    = DateTime.now().month;
    final lowSeason = VitaminDCalculator.isLowUVSeason(city, month);

    if (status == VitaminDStatus.toxic) {
      return 'Your Vitamin D is very high. Avoid further sun exposure today and skip supplements.';
    }
    if (status == VitaminDStatus.normal) {
      return '🎉 Daily target reached! You\'re all set. Maintain this routine for optimal health.';
    }
    if (lowSeason) {
      return '⚠️ $city is in a low-UV season. Consider increasing supplement intake — natural synthesis will be limited until March.';
    }
    if (uvIndex < 2) {
      return 'UV is low right now. Check back around 10–11 AM for the best exposure window.';
    }
    return 'Best sun exposure window today is 10:30–10:50 AM. Step outside for 20 min with arms exposed to reach your target.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1060),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3A2A6A), width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.bgHighlight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome,
              color: AppColors.aiPurple, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI RECOMMENDATION',
                style: TextStyle(
                    color: AppColors.aiPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(_tip,
                style: const TextStyle(
                    color: Color(0xFFC4C4E0),
                    fontSize: 13,
                    height: 1.5)),
          ],
        )),
      ]),
    );
  }
}