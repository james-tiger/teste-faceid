import 'package:lab_facial_delivy/decision_engine.dart';
import 'package:lab_facial_delivy/models.dart';
import 'package:test/test.dart';

FaceCapture capture(List<double> features, {double quality = 1}) => FaceCapture(
  jpegBase64: '',
  features: features,
  brightness: 0.5,
  contrast: 0.24 * quality,
  sharpness: 0.10 * quality,
);

void main() {
  const engine = DecisionEngine(DecisionThresholds());
  const reference = <double>[0.1, 0.3, 0.8, 0.7, 0.2, 0.9];

  test('aprova alta semelhança com movimento ativo plausível', () {
    final decision = engine.evaluate(
      reference: reference,
      neutral: capture(const [0.11, 0.29, 0.79, 0.71, 0.21, 0.89]),
      challenge: capture(const [0.18, 0.36, 0.72, 0.64, 0.28, 0.82]),
    );
    expect(decision.status, VerificationStatus.approved);
    expect(decision.similarity, greaterThan(0.9));
  });

  test('envia captura sem mudança para revisão manual', () {
    final neutral = capture(reference);
    final decision = engine.evaluate(
      reference: reference,
      neutral: neutral,
      challenge: neutral,
    );
    expect(decision.status, VerificationStatus.manualReview);
    expect(decision.reason, contains('Desafio'));
  });

  test('rejeita baixa semelhança quando demais sinais estão adequados', () {
    final decision = engine.evaluate(
      reference: reference,
      neutral: capture(const [0.9, 0.7, 0.2, 0.3, 0.8, 0.1]),
      challenge: capture(const [0.82, 0.62, 0.28, 0.38, 0.72, 0.18]),
    );
    expect(decision.status, VerificationStatus.rejected);
  });

  test('qualidade ruim nunca é aprovada automaticamente', () {
    final decision = engine.evaluate(
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
    );
    expect(decision.status, VerificationStatus.manualReview);
    expect(decision.reason, contains('Qualidade'));
  });
}
