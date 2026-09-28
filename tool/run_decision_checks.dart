import '../lib/decision_engine.dart';
import '../lib/models.dart';

FaceCapture capture(List<double> features, {double quality = 1}) => FaceCapture(
  jpegBase64: '',
  features: features,
  brightness: 0.5,
  contrast: 0.24 * quality,
  sharpness: 0.10 * quality,
);

void expectStatus(String name, Decision decision, VerificationStatus expected) {
  if (decision.status != expected) {
    throw StateError(
      '$name: esperado ${expected.name}, obtido ${decision.status.name}',
    );
  }
  print('OK  $name -> ${decision.status.name}');
}

void main() {
  const engine = DecisionEngine(DecisionThresholds());
  const reference = <double>[0.1, 0.3, 0.8, 0.7, 0.2, 0.9];

  expectStatus(
    'alta compatibilidade e vida plausível',
    engine.evaluate(
      reference: reference,
      neutral: capture(const [0.11, 0.29, 0.79, 0.71, 0.21, 0.89]),
      challenge: capture(const [0.18, 0.36, 0.72, 0.64, 0.28, 0.82]),
    ),
    VerificationStatus.approved,
  );
  final neutral = capture(reference);
  expectStatus(
    'desafio sem movimento',
    engine.evaluate(reference: reference, neutral: neutral, challenge: neutral),
    VerificationStatus.manualReview,
  );
  expectStatus(
    'baixa compatibilidade',
    engine.evaluate(
      reference: reference,
      neutral: capture(const [0.9, 0.7, 0.2, 0.3, 0.8, 0.1]),
      challenge: capture(const [0.82, 0.62, 0.28, 0.38, 0.72, 0.18]),
    ),
    VerificationStatus.rejected,
  );
  expectStatus(
    'baixa qualidade',
    engine.evaluate(
      reference: reference,
      neutral: capture(reference, quality: 0.02),
      challenge: capture(const [
        0.18,
        0.36,
        0.72,
        0.64,
        0.28,
        0.82,
      ], quality: 0.02),
    ),
    VerificationStatus.manualReview,
  );
  print('4 verificações concluídas com sucesso.');
}
