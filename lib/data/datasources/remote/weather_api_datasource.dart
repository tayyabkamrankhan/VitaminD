import 'package:dio/dio.dart';
import '../../models/weather_model.dart';
import '../../../core/constants/app_constants.dart';

class WeatherApiDatasource {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.weatherBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<WeatherData> fetchCurrent(double lat, double lon) async {
    final weatherRes = await _dio.get('/weather', queryParameters: {
      'lat': lat, 'lon': lon,
      'appid': AppConstants.weatherApiKey, 'units': 'metric',
    });
    final uvRes = await _dio.get('/uvi', queryParameters: {
      'lat': lat, 'lon': lon, 'appid': AppConstants.weatherApiKey,
    });
    return WeatherData.fromJson(
      weatherRes.data as Map<String, dynamic>,
      (uvRes.data['value'] as num).toDouble(),
    );
  }

  Future<List<HourlyUV>> fetchForecast(double lat, double lon) async {
    final res = await _dio.get('/forecast', queryParameters: {
      'lat': lat, 'lon': lon,
      'appid': AppConstants.weatherApiKey, 'units': 'metric', 'cnt': 8,
    });
    return (res.data['list'] as List)
        .map((item) => HourlyUV.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
