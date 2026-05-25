class WeatherData {
  final double uvIndex;
  final double temperatureC;
  final double cloudCoverPercent;
  final String condition;    // e.g. 'Clear', 'Clouds', 'Rain'
  final String cityName;
  final DateTime fetchedAt;

  const WeatherData({
    required this.uvIndex, required this.temperatureC,
    required this.cloudCoverPercent, required this.condition,
    required this.cityName, required this.fetchedAt,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, double uvIndex) {
    return WeatherData(
      uvIndex: uvIndex,
      temperatureC: (json['main']['temp'] as num).toDouble(),
      cloudCoverPercent: (json['clouds']['all'] as num).toDouble(),
      condition: (json['weather'] as List).first['main'] as String,
      cityName: json['name'] as String,
      fetchedAt: DateTime.now(),
    );
  }
}

class HourlyUV {
  final DateTime time;
  final double uvIndex;
  final double cloudCoverPercent;

  const HourlyUV({required this.time, required this.uvIndex, required this.cloudCoverPercent});

  factory HourlyUV.fromJson(Map<String, dynamic> json) => HourlyUV(
    time: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
    uvIndex: (json['uvi'] as num?)?.toDouble() ?? 0,
    cloudCoverPercent: (json['clouds']['all'] as num?)?.toDouble() ?? 0,
  );
}
