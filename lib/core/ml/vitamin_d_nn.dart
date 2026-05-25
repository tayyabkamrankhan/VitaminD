import 'dart:math';

class VitaminDNN {
  // 5 inputs: [uvIndex/16.0, durationMin/60.0, skinTone/6.0, bodyExposure, spf/100.0]
  // Hidden Layer: 8 neurons
  // Output Layer: 1 neuron (synthesisRateNormalized)

  List<List<double>> weightsHidden = List.generate(8, (_) => List.generate(5, (_) => 0.0));
  List<double> biasHidden = List.generate(8, (_) => 0.0);

  List<double> weightsOutput = List.generate(8, (_) => 0.0);
  double biasOutput = 0.0;

  VitaminDNN() {
    _initializeWeights();
  }

  void _initializeWeights() {
    // Physiological pre-trained weights for realistic initial predictions
    // These model positive contributions of UV & exposure, negative SPF, and skin tone dampening.
    weightsHidden = [
      [ 1.8,  1.2, -0.9,  1.5, -1.6], 
      [-0.4, -0.2,  1.1, -0.1,  0.2], 
      [ 1.0,  0.8, -0.4,  0.9, -1.0], 
      [ 1.4,  1.0, -0.7,  1.2, -1.3],
      [-0.1, -0.1, -0.6,  0.4,  0.1],
      [ 0.6,  0.4, -0.3,  0.5, -0.5],
      [ 1.1,  0.9, -0.5,  1.0, -1.1],
      [-0.2,  0.0,  0.4, -0.2, -0.1],
    ];
    biasHidden = [-0.3, 0.2, -0.1, -0.3, 0.0, -0.1, -0.2, 0.1];

    weightsOutput = [2.4, -1.0, 1.6, 2.1, -0.4, 0.8, 1.8, -0.2];
    biasOutput = -0.5;
  }

  double _relu(double x) => x > 0 ? x : 0;
  double _sigmoid(double x) => 1 / (1 + exp(-x));

  /// Predicts Vitamin D synthesis rate in IU/minute, scaled up to max bounds.
  double predict({
    required double uvIndex,
    required double durationMin,
    required int skinTone,
    required double bodyExposure,
    required int spf,
  }) {
    // Normalize inputs
    final inputs = [
      (uvIndex / 16.0).clamp(0.0, 1.0),
      (durationMin / 60.0).clamp(0.0, 1.0),
      (skinTone / 6.0).clamp(0.0, 1.0),
      bodyExposure.clamp(0.0, 1.0),
      (spf / 100.0).clamp(0.0, 1.0),
    ];

    // Hidden Layer Forward (ReLU)
    final hiddenOutputs = List<double>.filled(8, 0.0);
    for (int i = 0; i < 8; i++) {
      double sum = biasHidden[i];
      for (int j = 0; j < 5; j++) {
        sum += inputs[j] * weightsHidden[i][j];
      }
      hiddenOutputs[i] = _relu(sum);
    }

    // Output Layer Forward (Sigmoid)
    double outputSum = biasOutput;
    for (int i = 0; i < 8; i++) {
      outputSum += hiddenOutputs[i] * weightsOutput[i];
    }
    
    // Scale output to standard bounds (e.g. 0 to 1200 IU)
    final rateNormalized = _sigmoid(outputSum);
    return rateNormalized * 1500.0;
  }

  /// On-device training / weight adjustments (gradient descent backpropagation)
  void trainOnline({
    required double uvIndex,
    required double durationMin,
    required int skinTone,
    required double bodyExposure,
    required int spf,
    required double actualIU,
    double learningRate = 0.02,
  }) {
    // Normalize inputs
    final inputs = [
      (uvIndex / 16.0).clamp(0.0, 1.0),
      (durationMin / 60.0).clamp(0.0, 1.0),
      (skinTone / 6.0).clamp(0.0, 1.0),
      bodyExposure.clamp(0.0, 1.0),
      (spf / 100.0).clamp(0.0, 1.0),
    ];

    // Forward pass
    final hiddenSums = List<double>.filled(8, 0.0);
    final hiddenOutputs = List<double>.filled(8, 0.0);
    for (int i = 0; i < 8; i++) {
      double sum = biasHidden[i];
      for (int j = 0; j < 5; j++) {
        sum += inputs[j] * weightsHidden[i][j];
      }
      hiddenSums[i] = sum;
      hiddenOutputs[i] = _relu(sum);
    }

    double outputSum = biasOutput;
    for (int i = 0; i < 8; i++) {
      outputSum += hiddenOutputs[i] * weightsOutput[i];
    }
    
    final rateNormalized = _sigmoid(outputSum);
    final targetNormalized = (actualIU / 1500.0).clamp(0.0, 1.0);

    // Delta error
    final error = targetNormalized - rateNormalized;

    // Output layer gradients
    final outputGradient = error * rateNormalized * (1 - rateNormalized); // Sigmoid derivative
    
    // Update output weights and bias
    for (int i = 0; i < 8; i++) {
      weightsOutput[i] += learningRate * outputGradient * hiddenOutputs[i];
    }
    biasOutput += learningRate * outputGradient;

    // Hidden layer gradients (Backpropagation)
    for (int i = 0; i < 8; i++) {
      final reluDeriv = hiddenSums[i] > 0 ? 1.0 : 0.0;
      final hiddenGradient = outputGradient * weightsOutput[i] * reluDeriv;

      // Update hidden weights and bias
      for (int j = 0; j < 5; j++) {
        weightsHidden[i][j] += learningRate * hiddenGradient * inputs[j];
      }
      biasHidden[i] += learningRate * hiddenGradient;
    }
  }
}
