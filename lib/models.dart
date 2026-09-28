enum VerificationStatus { approved, manualReview, rejected }

class FaceCapture {
  const FaceCapture({
    required this.jpegBase64,
    required this.features,
    required this.brightness,
    required this.contrast,
    required this.sharpness,
  });

  final String jpegBase64;
  final List<double> features;
  final double brightness;
  final double contrast;
  final double sharpness;

  factory FaceCapture.fromMap(Map<Object?, Object?> map) => FaceCapture(
    jpegBase64: map['jpegBase64']! as String,
    features: (map['features']! as List<Object?>)
        .map((value) => (value! as num).toDouble())
        .toList(growable: false),
    brightness: (map['brightness']! as num).toDouble(),
    contrast: (map['contrast']! as num).toDouble(),
    sharpness: (map['sharpness']! as num).toDouble(),
  );
}

class Courier {
  const Courier({
    required this.id,
    required this.name,
    required this.documentLast4,
    required this.createdAt,
    required this.referenceTemplate,
    required this.consentVersion,
  });

  final String id;
  final String name;
  final String documentLast4;
  final DateTime createdAt;
  final List<double> referenceTemplate;
  final String consentVersion;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'documentLast4': documentLast4,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'referenceTemplate': referenceTemplate,
    'consentVersion': consentVersion,
  };

  factory Courier.fromJson(Map<String, Object?> json) => Courier(
    id: json['id']! as String,
    name: json['name']! as String,
    documentLast4: json['documentLast4']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    referenceTemplate: (json['referenceTemplate']! as List<Object?>)
        .map((value) => (value! as num).toDouble())
        .toList(growable: false),
    consentVersion: json['consentVersion']! as String,
  );
}

class VerificationAttempt {
  const VerificationAttempt({
    required this.id,
    required this.courierId,
    required this.courierName,
    required this.createdAt,
    required this.status,
    required this.similarity,
    required this.liveness,
    required this.quality,
    required this.challenge,
    required this.reason,
    required this.isDemo,
  });

  final String id;
  final String courierId;
  final String courierName;
  final DateTime createdAt;
  final VerificationStatus status;
  final double similarity;
  final double liveness;
  final double quality;
  final String challenge;
  final String reason;
  final bool isDemo;

  Map<String, Object?> toJson() => {
    'id': id,
    'courierId': courierId,
    'courierName': courierName,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'status': status.name,
    'similarity': similarity,
    'liveness': liveness,
    'quality': quality,
    'challenge': challenge,
    'reason': reason,
    'isDemo': isDemo,
  };

  factory VerificationAttempt.fromJson(Map<String, Object?> json) =>
      VerificationAttempt(
        id: json['id']! as String,
        courierId: json['courierId']! as String,
        courierName: json['courierName']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        status: VerificationStatus.values.byName(json['status']! as String),
        similarity: (json['similarity']! as num).toDouble(),
        liveness: (json['liveness']! as num).toDouble(),
        quality: (json['quality']! as num).toDouble(),
        challenge: json['challenge']! as String,
        reason: json['reason']! as String,
        isDemo: json['isDemo']! as bool,
      );
}

class Decision {
  const Decision({
    required this.status,
    required this.similarity,
    required this.liveness,
    required this.quality,
    required this.reason,
  });

  final VerificationStatus status;
  final double similarity;
  final double liveness;
  final double quality;
  final String reason;
}
