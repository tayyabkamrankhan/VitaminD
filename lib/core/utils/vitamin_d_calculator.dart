import '../constants/app_constants.dart';

enum VitaminDStatus { deficient, insufficient, normal, toxic }

class VitaminDCalculator {
  VitaminDCalculator._();

  /// Calculates IU of Vitamin D synthesized from UV exposure.
  /// Calibrated for South Asian (Fitzpatrick IV–VI) populations.
  ///
  /// [uvIndex]      — live UV index from sensor or weather API
  /// [durationMin]  — exposure duration in minutes
  /// [skinTone]     — Fitzpatrick scale 1–6
  /// [bodyExposure] — fraction of body exposed (0.0–1.0)
  /// [spf]          — sunscreen SPF; 0 = no sunscreen
  /// [altitude]     — metres above sea level
  /// [cloudCover]   — 0–100 percent cloud coverage
  static double calculateSynthesis({
    required double uvIndex,
    required double durationMin,
    required int skinTone,
    required double bodyExposure,
    int spf = 0,
    double altitude = 0,
    double cloudCover = 0,
  }) {
    if (uvIndex <= 0 || durationMin <= 0) return 0;

    const double baseSynthesisRate = 400.0; // IU/min baseline (Fitz I, UV 3)

    final skinFactor      = AppConstants.skinToneFactors[skinTone] ?? 0.55;
    final uvFactor        = uvIndex / 3.0;
    final spfFactor       = spf > 0 ? 1.0 / (spf * 0.75) : 1.0;
    final altitudeFactor  = 1.0 + (altitude / 300) * 0.04;
    final cloudFactor     = 1.0 - (cloudCover / 100) * 0.75;

    final iuSynthesized = baseSynthesisRate
        * uvFactor
        * skinFactor
        * bodyExposure
        * spfFactor
        * altitudeFactor
        * cloudFactor
        * durationMin;

    return iuSynthesized.clamp(0, AppConstants.toxicThreshold);
  }

  /// Minutes needed to reach daily target given current conditions.
  static double minutesNeeded({
    required double uvIndex,
    required int skinTone,
    required double bodyExposure,
    required double currentIU,
    required int ageYears,
    int spf = 0,
    double altitude = 0,
    double cloudCover = 0,
  }) {
    final target = _targetIU(ageYears);
    final remaining = (target - currentIU).clamp(0, target);
    if (remaining == 0) return 0;

    final ratePerMin = calculateSynthesis(
      uvIndex: uvIndex,
      durationMin: 1,
      skinTone: skinTone,
      bodyExposure: bodyExposure,
      spf: spf,
      altitude: altitude,
      cloudCover: cloudCover,
    );

    if (ratePerMin <= 0) return double.infinity;
    return remaining / ratePerMin;
  }

  /// ML-like deterministic regression model to predict safe exposure limit before sunburn/toxicity
  static double calculateSafeExposureLimit({
    required double uvIndex,
    required int skinTone,
    int spf = 0,
  }) {
    if (uvIndex <= 0.1) return double.infinity;
    
    // Base minutes to burn at UV index 1 for Fitzpatrick Type I
    const double baseBurnMinutes = 150.0;
    
    final skinFactor = AppConstants.skinToneFactors[skinTone] ?? 0.55;
    // SPF directly multiplies the time you can stay in the sun safely
    final spfFactor = spf > 0 ? spf.toDouble() : 1.0;
    
    // The darker the skin (lower skinFactor), the longer the safe limit.
    // E.g., Type I = 1.0 -> 150 / UV. Type VI = 0.3 -> 500 / UV.
    final safeMinutes = (baseBurnMinutes / skinFactor / uvIndex) * spfFactor;
    
    return safeMinutes;
  }

  static double totalDailyIU({
    required double synthesizedIU,
    required double supplementIU,
    required double dietaryIU,
  }) => synthesizedIU + supplementIU + dietaryIU;

  static VitaminDStatus getStatus(double totalIU, int ageYears) {
    final target = _targetIU(ageYears);
    if (totalIU >= AppConstants.toxicThreshold) return VitaminDStatus.toxic;
    if (totalIU >= target * AppConstants.normalMinRatio) return VitaminDStatus.normal;
    if (totalIU >= target * AppConstants.insuffMinRatio) return VitaminDStatus.insufficient;
    return VitaminDStatus.deficient;
  }

  static String statusLabel(VitaminDStatus status) {
    switch (status) {
      case VitaminDStatus.normal:       return 'Normal';
      case VitaminDStatus.insufficient: return 'Insufficient';
      case VitaminDStatus.deficient:    return 'Deficient';
      case VitaminDStatus.toxic:        return 'Too High';
    }
  }

  static double progressRatio(double totalIU, int ageYears) {
    final target = _targetIU(ageYears);
    return (totalIU / target).clamp(0.0, 1.0);
  }

  static double _targetIU(int age) {
    if (age < 1)  return AppConstants.targetIUChild;
    if (age > 70) return AppConstants.targetIUElderly;
    return AppConstants.targetIUAdult;
  }

  /// Skin tone auto-detection from RGB sensor (TCS3200)
  /// Maps raw RGB values to nearest Fitzpatrick scale 1–6
  static int detectSkinTone(int r, int g, int b) {
    final brightness = (r * 0.299 + g * 0.587 + b * 0.114);
    if (brightness > 220) return 1;
    if (brightness > 190) return 2;
    if (brightness > 155) return 3;
    if (brightness > 115) return 4;
    if (brightness > 75)  return 5;
    return 6;
  }

  /// Whether current month is a low-UV season for the user's city
  static bool isLowUVSeason(String city, int month) {
    final lowMonths = AppConstants.lowUVMonths[city] ?? [];
    return lowMonths.contains(month);
  }
}
