import 'package:dio/dio.dart';
import '../../data/models/weather_model.dart';
import '../constants/app_constants.dart';

class WeatherService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.weatherBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Fetch current weather + UV index for given lat/lon
  Future<WeatherData> fetchWeather(double lat, double lon) async {
    try {
      // Current weather
      final weatherRes = await _dio.get('/weather', queryParameters: {
        'lat': lat, 'lon': lon,
        'appid': AppConstants.weatherApiKey, 'units': 'metric',
      });

      // UV index (separate endpoint)
      final uvRes = await _dio.get('/uvi', queryParameters: {
        'lat': lat, 'lon': lon, 'appid': AppConstants.weatherApiKey,
      });

      return WeatherData.fromJson(
        weatherRes.data as Map<String, dynamic>,
        (uvRes.data['value'] as num).toDouble(),
      );
    } on DioException catch (e) {
      throw WeatherException(e.message ?? 'Weather fetch failed');
    }
  }

  /// Fetch hourly UV forecast for the next 24 hours
  Future<List<HourlyUV>> fetchUVForecast(double lat, double lon) async {
    try {
      final res = await _dio.get('/forecast', queryParameters: {
        'lat': lat, 'lon': lon,
        'appid': AppConstants.weatherApiKey, 'units': 'metric', 'cnt': 8,
      });
      final list = res.data['list'] as List;
      return list.map((item) => HourlyUV.fromJson(item)).toList();
    } on DioException {
      return [];
    }
  }

  /// Find best exposure window in next 8 forecast slots
  String? bestExposureWindow(List<HourlyUV> forecast) {
    HourlyUV? best;
    for (final h in forecast) {
      final hour = h.time.hour;
      if (hour < 10 || hour > 14) continue; // Only effective hours
      if (h.uvIndex >= 3.0) {
        if (best == null || h.uvIndex > best.uvIndex) best = h;
      }
    }
    if (best == null) return null;
    final start = '${best.time.hour}:00';
    final end   = '${best.time.hour}:20';
    return '$start – $end';
  }
}

class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);
}
