/// UV index helpers and descriptors

class UVUtils {
  UVUtils._();

  /// Human-readable UV level label
  static String uvLabel(double uvIndex) {
    if (uvIndex < 3)  return 'Low';
    if (uvIndex < 6)  return 'Moderate';
    if (uvIndex < 8)  return 'High';
    if (uvIndex < 11) return 'Very High';
    return 'Extreme';
  }

  /// Recommended max unprotected exposure in minutes for Fitzpatrick V (South Asian default)
  static double maxSafeMinutes(double uvIndex, int fitzpatrick) {
    if (uvIndex <= 0) return double.infinity;
    // MED (Minimal Erythemal Dose) base for each skin type (minutes at UV=1)
    const medBase = {1: 67, 2: 100, 3: 133, 4: 200, 5: 267, 6: 400};
    final base = (medBase[fitzpatrick] ?? 267).toDouble();
    return base / uvIndex;
  }

  /// Whether UV is high enough for meaningful synthesis (>= 3)
  static bool isSynthesisViable(double uvIndex) => uvIndex >= 3.0;

  /// UVB is only effective when sun is high enough (altitude angle > 35°)
  /// Approximated by: effective hours are roughly 10 AM – 2 PM in South Asia
  static bool isEffectiveHour(DateTime time) {
    final hour = time.hour;
    return hour >= 10 && hour <= 14;
  }

  /// Percentage of UVB blocked by cloud cover
  static double cloudReduction(double cloudPercent) =>
      (cloudPercent / 100.0) * 0.75;

  /// Altitude UV boost: ~4% per 300m gain
  static double altitudeBoost(double altitudeMetres) =>
      1.0 + (altitudeMetres / 300.0) * 0.04;
}
