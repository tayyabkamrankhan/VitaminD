import 'package:geolocator/geolocator.dart';
import '../../core/services/weather_service.dart';
import '../../core/services/location_service.dart';
import '../models/weather_model.dart';

class WeatherRepository {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  Future<WeatherData> getWeather(String? fallbackCity) async {
    Position? pos;
    try {
      pos = await _locationService.getCurrentPosition();
    } catch (_) {}
    
    if (pos == null) {
      final coords = _getCityCoords(fallbackCity);
      return _weatherService.fetchWeather(coords.$1, coords.$2);
    }
    return _weatherService.fetchWeather(pos.latitude, pos.longitude);
  }

  Future<String?> getBestExposureWindow(String? fallbackCity) async {
    Position? pos;
    try {
      pos = await _locationService.getCurrentPosition();
    } catch (_) {}

    final coords = pos != null ? (pos.latitude, pos.longitude) : _getCityCoords(fallbackCity);
    final forecast = await _weatherService.fetchUVForecast(coords.$1, coords.$2);
    return _weatherService.bestExposureWindow(forecast);
  }

  (double, double) _getCityCoords(String? cityName) {
    const cities = {
      'karachi':    (24.8607, 67.0011),
      'lahore':     (31.5204, 74.3587),
      'islamabad':  (33.6844, 73.0479),
      'rawalpindi': (33.6007, 73.0679),
      'peshawar':   (34.0151, 71.5249),
      'multan':     (30.1575, 71.5249),
      'quetta':     (30.1798, 66.9750),
      'faisalabad': (31.4504, 73.1350),
    };
    final key = (cityName ?? 'rawalpindi').trim().toLowerCase();
    return cities[key] ?? cities['rawalpindi']!;
  }
}
