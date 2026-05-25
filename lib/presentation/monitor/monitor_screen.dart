import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/vitamin_d_calculator.dart';
import '../../providers/providers.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usb  = context.watch<USBProvider>();
    final uv   = context.watch<UVDataProvider>();
    final auth = context.watch<AuthProvider>();

    return SafeArea(
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Real-time UV', 
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text('Sensor Monitor', 
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        SliverAppBar(
          title: const Text('Live Monitor'),
          pinned: true,
          actions: [
            IconButton(
              icon: Icon(usb.connected ? Icons.usb_off_rounded : Icons.usb_rounded),
              onPressed: () => usb.connected
                  ? usb.disconnect()
                  : _showPortPicker(context),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (!usb.connected)
                _ConnectCard(onTap: () => _showPortPicker(context))
              else 
                _LiveUVCard(reading: usb.latestReading),
                
              const SizedBox(height: 12),
              _ClothingSelector(current: uv.bodyExposure, onChanged: uv.setBodyExposure),
              const SizedBox(height: 12),
              _SPFSelector(current: uv.spf, onChanged: uv.setSpf),
              const SizedBox(height: 12),
              if (usb.latestReading != null)
                _HealthWarningCard(
                  uvIndex: usb.latestReading!.uvIndex,
                  skinTone: auth.profile?.skinTone ?? 5,
                  spf: uv.spf,
                ),
              _SessionCard(
                active:      uv.sessionActive,
                minutes:     uv.sessionMinutes,
                synthesized: uv.synthesizedIU,
                onStart: () {
                  uv.startSession();
                  if (usb.latestReading != null) {
                    uv.updateFromSensor(usb.latestReading!.uvIndex);
                  }
                },
                onStop: () async {
                  if (auth.profile != null) await uv.stopSession(auth.profile!.uid);
                },
              ),
              if (usb.error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: usb.error!),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  void _showPortPicker(BuildContext context) async {
    final usb = context.read<USBProvider>();
    await usb.scanPorts();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PortPicker(
        ports: usb.ports,
        onSelect: (port) async {
          Navigator.pop(context);
          await usb.connect(port);
        },
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ConnectCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ConnectCard({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(children: [
        const Icon(Icons.usb_rounded, size: 52, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Text('Connect your sensor watch',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Android: plug in via USB OTG\nDesktop: connect via USB cable',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.search),
            label: const Text('Scan for ports')),
      ]),
    ),
  );
}

class _LiveUVCard extends StatelessWidget {
  final dynamic reading;
  const _LiveUVCard({required this.reading});
  @override
  Widget build(BuildContext context) {
    final uv   = reading?.uvIndex ?? 0.0;
    final fitz = reading?.fitzpatrickTone ?? 5;
    final temp = reading?.temperatureC ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(children: [
        const Text('LIVE SENSOR DATA', style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 16),
        Text(uv.toStringAsFixed(1), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: AppColors.sunYellow)),
        const Text('UV index', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _Metric(label: 'Skin tone', value: 'Fitz. $fitz', color: AppColors.accent),
          _Metric(label: 'Temperature', value: '${temp.toStringAsFixed(1)}°C', color: AppColors.uvColor),
        ]),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value; final Color color;
  const _Metric({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
  ]);
}

class _ClothingSelector extends StatelessWidget {
  final double current; final void Function(double) onChanged;
  const _ClothingSelector({required this.current, required this.onChanged});
  static const _opts = [
    {'label': 'Fully exposed', 'icon': Icons.person_outline, 'value': 1.0},
    {'label': 'Half exposed',  'icon': Icons.person,          'value': 0.5},
    {'label': 'Minimal',       'icon': Icons.accessibility_new,'value': 0.2},
  ];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Clothing coverage', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const SizedBox(height: 10),
      Row(children: _opts.map((o) {
        final sel = (o['value'] as double) == current;
        return Expanded(child: GestureDetector(
          onTap: () => onChanged(o['value'] as double),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: sel ? AppColors.bgHighlight : AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 1.5 : 0.5)),
            child: Column(children: [
              Icon(o['icon'] as IconData, color: sel ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(o['label'] as String, style: TextStyle(fontSize: 10, color: sel ? AppColors.primary : AppColors.textMuted), textAlign: TextAlign.center),
            ]),
          ),
        ));
      }).toList()),
    ],
  );
}

class _SPFSelector extends StatelessWidget {
  final int current; final void Function(int) onChanged;
  const _SPFSelector({required this.current, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    const opts = [0, 15, 30, 50];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sunscreen SPF', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        Row(children: opts.map((spf) {
          final sel = spf == current;
          return Expanded(child: GestureDetector(
            onTap: () => onChanged(spf),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? AppColors.bgHighlight : AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 1.5 : 0.5)),
              child: Center(child: Text(spf == 0 ? 'None' : 'SPF $spf',
                  style: TextStyle(fontSize: 12, color: sel ? AppColors.primary : AppColors.textMuted, fontWeight: sel ? FontWeight.w600 : FontWeight.normal))),
            ),
          ));
        }).toList()),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final bool active; final double minutes, synthesized;
  final VoidCallback onStart, onStop;
  const _SessionCard({required this.active, required this.minutes, required this.synthesized, required this.onStart, required this.onStop});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(children: [
      if (active) ...[
        Text('${minutes.round()} min', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.accent)),
        Text('+${synthesized.round()} IU synthesised', style: const TextStyle(color: AppColors.statusNormal, fontSize: 15)),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: onStop, icon: const Icon(Icons.stop_rounded), label: const Text('Stop session'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDeficient)),
      ] else ...[
        const Text('Start an exposure session', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Track real-time UV synthesis while outside', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start session')),
      ],
    ]),
  );
}

class _PortPicker extends StatelessWidget {
  final List<String> ports;
  final void Function(String) onSelect;
  const _PortPicker({required this.ports, required this.onSelect});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select serial port', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Android: appears as USB device\nDesktop: COM3, /dev/ttyUSB0, etc.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 16),
      if (ports.isEmpty)
        const Text('No ports found. Check your USB connection and try again.',
            style: TextStyle(color: AppColors.textSecondary))
      else
        ...ports.map((p) => ListTile(
          leading: const Icon(Icons.usb_rounded, color: AppColors.primary),
          title: Text(p),
          onTap: () => onSelect(p),
        )),
    ]),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.statusDeficientBg, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.statusDeficient, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(color: AppColors.statusDeficient, fontSize: 13))),
    ]),
  );
}

class _HealthWarningCard extends StatelessWidget {
  final double uvIndex;
  final int skinTone;
  final int spf;

  const _HealthWarningCard({
    required this.uvIndex,
    required this.skinTone,
    required this.spf,
  });

  @override
  Widget build(BuildContext context) {
    if (uvIndex <= 0.1) return const SizedBox.shrink();

    final safeLimit = VitaminDCalculator.calculateSafeExposureLimit(
      uvIndex: uvIndex, skinTone: skinTone, spf: spf,
    );
    
    final isInfinite = safeLimit == double.infinity;
    final displayMinutes = isInfinite ? '∞' : safeLimit.round().toString();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusDeficient, width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.statusDeficient, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HEALTHY LIMIT: $displayMinutes MIN', 
                  style: const TextStyle(color: AppColors.statusDeficient, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              const Text('AI Warning: Exceeding this limit based on your skin tone and current UV index will cause sunburn and toxicity.',
                  style: TextStyle(color: Color(0xFFE0C4C4), fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }
}
