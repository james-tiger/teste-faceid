import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'decision_engine.dart';
import 'models.dart';
import 'native_bridge.dart';

class AppStore extends ChangeNotifier {
  AppStore(this.bridge);

  final DeviceBridge bridge;
  Courier? courier;
  final List<VerificationAttempt> attempts = [];
  Map<String, Object?> diagnostics = const {};
  bool ready = false;
  String? startupError;

  final DecisionThresholds thresholds = const DecisionThresholds();

  Future<void> initialize() async {
    try {
      final raw = await bridge.loadEncryptedState();
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, Object?>;
        final courierJson = json['courier'];
        if (courierJson is Map<String, Object?>) {
          courier = Courier.fromJson(courierJson);
        }
        final attemptJson = json['attempts'];
        if (attemptJson is List<Object?>) {
          attempts.addAll(
            attemptJson.whereType<Map<String, Object?>>().map(
              VerificationAttempt.fromJson,
            ),
          );
        }
      } else {
        attempts.addAll(_demoAttempts());
        await _persist();
      }
      diagnostics = await bridge.diagnostics();
    } catch (error) {
      startupError = error.toString();
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> registerCourier({
    required String id,
    required String name,
    required String documentLast4,
    required List<double> template,
  }) async {
    courier = Courier(
      id: id,
      name: name,
      documentLast4: documentLast4,
      createdAt: DateTime.now(),
      referenceTemplate: List.unmodifiable(template),
      consentVersion: 'LAB-PRIVACIDADE-1.0',
    );
    await _persist();
    notifyListeners();
  }

  Future<VerificationAttempt> verify({
    required FaceCapture neutral,
    required FaceCapture challenge,
    required String challengeText,
  }) async {
    final current = courier;
    if (current == null) throw StateError('Cadastre um motoboy primeiro.');
    final decision = DecisionEngine(thresholds).evaluate(
      reference: current.referenceTemplate,
      neutral: neutral,
      challenge: challenge,
    );
    final now = DateTime.now();
    final attempt = VerificationAttempt(
      id: 'ATT-${now.microsecondsSinceEpoch}',
      courierId: current.id,
      courierName: current.name,
      createdAt: now,
      status: decision.status,
      similarity: decision.similarity,
      liveness: decision.liveness,
      quality: decision.quality,
      challenge: challengeText,
      reason: decision.reason,
      isDemo: false,
    );
    attempts.insert(0, attempt);
    if (attempts.length > 50) attempts.removeRange(50, attempts.length);
    await _persist();
    notifyListeners();
    return attempt;
  }

  Future<void> clearAll() async {
    courier = null;
    attempts.clear();
    await bridge.purgeEncryptedState();
    diagnostics = await bridge.diagnostics();
    notifyListeners();
  }

  Future<void> restoreDemoHistory() async {
    attempts
      ..removeWhere((attempt) => attempt.isDemo)
      ..addAll(_demoAttempts());
    await _persist();
    notifyListeners();
  }

  Future<void> refreshDiagnostics() async {
    diagnostics = await bridge.diagnostics();
    notifyListeners();
  }

  Future<void> _persist() => bridge.saveEncryptedState(
    jsonEncode({
      'schema': 1,
      'courier': courier?.toJson(),
      'attempts': attempts.map((attempt) => attempt.toJson()).toList(),
    }),
  );

  static List<VerificationAttempt> _demoAttempts() {
    final now = DateTime.now();
    return [
      VerificationAttempt(
        id: 'DEMO-001',
        courierId: 'MOTO-1042',
        courierName: 'Ana Souza (fictício)',
        createdAt: now.subtract(const Duration(hours: 3)),
        status: VerificationStatus.approved,
        similarity: 0.91,
        liveness: 0.08,
        quality: 0.84,
        challenge: 'Vire levemente o rosto para a esquerda',
        reason: 'Registro fictício para demonstração.',
        isDemo: true,
      ),
      VerificationAttempt(
        id: 'DEMO-002',
        courierId: 'MOTO-2051',
        courierName: 'Carlos Lima (fictício)',
        createdAt: now.subtract(const Duration(days: 1)),
        status: VerificationStatus.manualReview,
        similarity: 0.74,
        liveness: 0.04,
        quality: 0.51,
        challenge: 'Vire levemente o rosto para a direita',
        reason: 'Registro fictício para demonstração.',
        isDemo: true,
      ),
      VerificationAttempt(
        id: 'DEMO-003',
        courierId: 'MOTO-3098',
        courierName: 'João Silva (fictício)',
        createdAt: now.subtract(const Duration(days: 2)),
        status: VerificationStatus.rejected,
        similarity: 0.55,
        liveness: 0.07,
        quality: 0.79,
        challenge: 'Incline levemente o queixo para baixo',
        reason: 'Registro fictício para demonstração.',
        isDemo: true,
      ),
    ];
  }
}
