import 'dart:math' as math;

import 'models.dart';

class DecisionThresholds {
  const DecisionThresholds({
    this.approveSimilarity = 0.82,
    this.reviewSimilarity = 0.68,
    this.minimumLiveness = 0.025,
    this.maximumLiveness = 0.42,
    this.minimumQuality = 0.45,
  });

  final double approveSimilarity;
  final double reviewSimilarity;
  final double minimumLiveness;
  final double maximumLiveness;
  final double minimumQuality;
}

class DecisionEngine {
  const DecisionEngine(this.thresholds);

  final DecisionThresholds thresholds;

  Decision evaluate({
    required List<double> reference,
    required FaceCapture neutral,
    required FaceCapture challenge,
  }) {
    final similarity = normalizedCorrelation(reference, neutral.features);
    final liveness = meanAbsoluteDifference(
      neutral.features,
      challenge.features,
    );
    final quality = _quality(neutral, challenge);
    final livenessOk =
        liveness >= thresholds.minimumLiveness &&
        liveness <= thresholds.maximumLiveness;

    if (quality < thresholds.minimumQuality) {
      return Decision(
        status: VerificationStatus.manualReview,
        similarity: similarity,
        liveness: liveness,
        quality: quality,
        reason: 'Qualidade insuficiente; encaminhar para revisão humana.',
      );
    }
    if (!livenessOk) {
      return Decision(
        status: VerificationStatus.manualReview,
        similarity: similarity,
        liveness: liveness,
        quality: quality,
        reason: 'Desafio ativo inconclusivo; revisão humana obrigatória.',
      );
    }
    if (similarity >= thresholds.approveSimilarity) {
      return Decision(
        status: VerificationStatus.approved,
        similarity: similarity,
        liveness: liveness,
        quality: quality,
        reason: 'Compatibilidade acima do limiar e mudança ativa dentro da faixa experimental do LAB.',
      );
    }
    if (similarity >= thresholds.reviewSimilarity) {
      return Decision(
        status: VerificationStatus.manualReview,
        similarity: similarity,
        liveness: liveness,
        quality: quality,
        reason: 'Faixa intermediária; uma pessoa deve decidir.',
      );
    }
    return Decision(
      status: VerificationStatus.rejected,
      similarity: similarity,
      liveness: liveness,
      quality: quality,
      reason: 'Baixa compatibilidade; não aplicar consequência automática.',
    );
  }

  static double normalizedCorrelation(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    final meanA = a.reduce((x, y) => x + y) / a.length;
    final meanB = b.reduce((x, y) => x + y) / b.length;
    var numerator = 0.0;
    var sumA = 0.0;
    var sumB = 0.0;
    for (var i = 0; i < a.length; i++) {
      final da = a[i] - meanA;
      final db = b[i] - meanB;
      numerator += da * db;
      sumA += da * da;
      sumB += db * db;
    }
    final denominator = math.sqrt(sumA * sumB);
    if (denominator == 0) return 0;
    return ((numerator / denominator) + 1) / 2;
  }

  static double meanAbsoluteDifference(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]).abs();
    }
    return sum / a.length;
  }

  static double _quality(FaceCapture a, FaceCapture b) {
    double score(FaceCapture capture) {
      final exposure = 1 - ((capture.brightness - 0.5).abs() * 1.6);
      final contrast = (capture.contrast / 0.24).clamp(0.0, 1.0);
      final sharpness = (capture.sharpness / 0.10).clamp(0.0, 1.0);
      return (exposure.clamp(0.0, 1.0) * 0.35) +
          (contrast * 0.25) +
          (sharpness * 0.40);
    }

    return (score(a) + score(b)) / 2;
  }
}
