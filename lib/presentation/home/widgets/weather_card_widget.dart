import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/weather_provider.dart';
import '../../../providers/auth_provider.dart';

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
          ? const Center(child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)))
          : w.error != null
              ? Row(children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  const Text('Weather unavailable',
                      style: TextStyle(color: AppColors.textMuted)),
                  const Spacer(),
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
                        style: const TextStyle(color: AppColors.uvColor,
                            fontSize: 20, fontWeight: FontWeight.w600)),
                    const Text('UV index', style: TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
                  ]),
                ]),
    );
  }

  IconData _weatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':       return Icons.wb_sunny_rounded;
      case 'clouds':      return Icons.cloud_rounded;
      case 'rain':
      case 'drizzle':     return Icons.grain_rounded;
      case 'thunderstorm':return Icons.thunderstorm_rounded;
      case 'snow':        return Icons.ac_unit_rounded;
      default:            return Icons.wb_sunny_rounded;
    }
  }
}
