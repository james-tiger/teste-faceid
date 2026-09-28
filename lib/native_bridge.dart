import 'package:flutter/services.dart';

import 'models.dart';

abstract class DeviceBridge {
  Future<FaceCapture?> capturePhoto(String purpose);
  Future<void> saveEncryptedState(String json);
  Future<String?> loadEncryptedState();
  Future<void> purgeEncryptedState();
  Future<Map<String, Object?>> diagnostics();
}

class NativeDeviceBridge implements DeviceBridge {
  static const MethodChannel _channel = MethodChannel(
    'lab_facial_delivy/device',
  );

  @override
  Future<FaceCapture?> capturePhoto(String purpose) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'capturePhoto',
      {'purpose': purpose},
    );
    return result == null ? null : FaceCapture.fromMap(result);
  }

  @override
  Future<void> saveEncryptedState(String json) =>
      _channel.invokeMethod<void>('saveEncryptedState', {'json': json});

  @override
  Future<String?> loadEncryptedState() =>
      _channel.invokeMethod<String>('loadEncryptedState');

  @override
  Future<void> purgeEncryptedState() =>
      _channel.invokeMethod<void>('purgeEncryptedState');

  @override
  Future<Map<String, Object?>> diagnostics() async {
    final value = await _channel.invokeMapMethod<String, Object?>(
      'diagnostics',
    );
    return value ?? const {};
  }
}
