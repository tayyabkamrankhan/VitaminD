import '../core/ml/vitamin_d_nn.dart';

class TFLiteService {
  final _nn = VitaminDNN();
  bool _loaded = true;

  /// Load model (always succeeds with pure-Dart offline model)
  Future<void> loadModel() async {
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  /// Predict personalised synthesis IU given inputs.
  Future<double> predictSynthesis({
    required double uvIndex,
    required double durationMin,
    required int skinTone,
    required double bodyExposure,
    required int spf,
  }) async {
    try {
      return _nn.predict(
        uvIndex: uvIndex,
        durationMin: durationMin,
        skinTone: skinTone,
        bodyExposure: bodyExposure,
        spf: spf,
      );
    } catch (_) {
      return -1;
    }
  }

  /// Update model weights based on new user data point (online backpropagation).
  Future<void> recordFeedback({
    required double uvIndex,
    required double durationMin,
    required int skinTone,
    required double bodyExposure,
    required int spf,
    required double actualIU,
  }) async {
    try {
      _nn.trainOnline(
        uvIndex: uvIndex,
        durationMin: durationMin,
        skinTone: skinTone,
        bodyExposure: bodyExposure,
        spf: spf,
        actualIU: actualIU,
      );
    } catch (_) {}
  }

  void dispose() {
    _loaded = false;
  }
}