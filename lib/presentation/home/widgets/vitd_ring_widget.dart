import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/vitamin_d_calculator.dart';

class VitDRingWidget extends StatefulWidget {
  final double totalIU, synthesizedIU, supplementIU, progressRatio;
  final VitaminDStatus status;
  final int age;

  const VitDRingWidget({super.key,
    required this.totalIU, required this.synthesizedIU,
    required this.supplementIU, required this.status,
    required this.progressRatio, required this.age});

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
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
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
      builder: (_, __) => Center(child: SizedBox(
        width: 220, height: 220,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _RingPainter(ratio: _anim.value, color: _ringColor),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${widget.totalIU.round()}',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Text('IU today', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            _StatusBadge(status: widget.status),
          ]),
        ]),
      )),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double ratio; final Color color;
  const _RingPainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.width - sw) / 2;

    canvas.drawCircle(center, r, Paint()
      ..color = AppColors.bgCardAlt ..strokeWidth = sw
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round);

    canvas.drawArc(Rect.fromCircle(center: center, radius: r),
      -math.pi / 2, 2 * math.pi * ratio.clamp(0, 1), false,
      Paint()..color = color ..strokeWidth = sw
        ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round);
  }

  @override bool shouldRepaint(_RingPainter old) => old.ratio != ratio;
}

class _StatusBadge extends StatelessWidget {
  final VitaminDStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      VitaminDStatus.normal       => (AppColors.statusNormalBg,    AppColors.statusNormal),
      VitaminDStatus.insufficient => (AppColors.statusInsuffBg,    AppColors.statusInsuff),
      VitaminDStatus.deficient    => (AppColors.statusDeficientBg, AppColors.statusDeficient),
      VitaminDStatus.toxic        => (AppColors.statusToxicBg,     AppColors.statusToxic),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(VitaminDCalculator.statusLabel(status),
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
