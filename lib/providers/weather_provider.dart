import 'package:flutter/foundation.dart';
import '../data/models/weather_model.dart';
import '../data/repositories/weather_repository.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherRepository _repo;
  WeatherData? _weather;
  String? _bestWindow;
  bool _loading = false;
  String? _error;

  WeatherProvider(this._repo);

  WeatherData? get weather     => _weather;
  String?      get bestWindow  => _bestWindow;
  bool         get loading     => _loading;
  String?      get error       => _error;
  double       get uvIndex     => _weather?.uvIndex ?? 0.0;

  Future<void> fetchWeather([String? fallbackCity]) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _weather     = await _repo.getWeather(fallbackCity);
      _bestWindow  = await _repo.getBestExposureWindow(fallbackCity);
    } catch (e) {
      _error = 'Could not fetch weather. Check internet connection.';
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
