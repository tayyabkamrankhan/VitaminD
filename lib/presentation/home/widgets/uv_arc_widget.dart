import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class UVArcWidget extends StatefulWidget {
  final double uvIndex; // 0–16
  const UVArcWidget({super.key, required this.uvIndex});

  @override
  State<UVArcWidget> createState() => _UVArcWidgetState();
}

class _UVArcWidgetState extends State<UVArcWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(
      begin: 0.0,
      end: (widget.uvIndex / 16.0).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(UVArcWidget old) {
    super.didUpdateWidget(old);
    if (old.uvIndex != widget.uvIndex) {
      _anim = Tween<double>(
        begin: _anim.value,
        end: (widget.uvIndex / 16.0).clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _uvColor(double uv) {
    if (uv < 3)  return AppColors.statusNormal;
    if (uv < 6)  return AppColors.sunYellow;
    if (uv < 8)  return AppColors.uvColor;
    if (uv < 11) return Colors.deepOrange;
    return AppColors.statusDeficient;
  }

  String _uvLabel(double uv) {
    if (uv < 3)  return 'Low';
    if (uv < 6)  return 'Moderate';
    if (uv < 8)  return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Column(children: [
        SizedBox(
          width: 160, height: 90,
          child: CustomPaint(
            painter: _ArcPainter(
              ratio: _anim.value,
              color: _uvColor(widget.uvIndex),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.uvIndex.toStringAsFixed(1),
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _uvColor(widget.uvIndex)),
        ),
        Text(
          _uvLabel(widget.uvIndex),
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12),
        ),
      ]),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double ratio;
  final Color color;
  const _ArcPainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;
    const sw = 12.0;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, math.pi, false,
      Paint()
        ..color = AppColors.bgCardAlt
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Fill
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, math.pi * ratio.clamp(0.0, 1.0), false,
      Paint()
        ..color = color
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.ratio != ratio || old.color != color;
}