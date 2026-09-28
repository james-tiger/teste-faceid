import 'package:flutter_test/flutter_test.dart';
import 'package:lab_facial_delivy/app_store.dart';
import 'package:lab_facial_delivy/main.dart';
import 'package:lab_facial_delivy/models.dart';
import 'package:lab_facial_delivy/native_bridge.dart';

class FakeBridge implements DeviceBridge {
  String? state;

  @override
  Future<FaceCapture?> capturePhoto(String purpose) async => null;

  @override
  Future<Map<String, Object?>> diagnostics() async => {
    'platform': 'Android teste',
    'encryptedStateExists': state != null,
  };

  @override
  Future<String?> loadEncryptedState() async => state;

  @override
  Future<void> purgeEncryptedState() async => state = null;

  @override
  Future<void> saveEncryptedState(String json) async => state = json;
}

void main() {
  testWidgets('abre painel local com avisos de segurança', (tester) async {
    final store = AppStore(FakeBridge());
    await store.initialize();
    await tester.pumpWidget(LabFacialApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('LAB Facial Delivy'), findsOneWidget);
    expect(find.text('Ambiente de laboratório'), findsOneWidget);
    expect(
      find.textContaining('decisão de trabalho automática'),
      findsOneWidget,
    );
    expect(find.text('Tentativas'), findsOneWidget);
  });
}
