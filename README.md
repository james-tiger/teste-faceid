# LAB Facial Delivy

Protótipo Flutter Android, local e isolado, para experimentar verificação de identidade facial 1:1 de motoboys. Este repositório não depende nem altera o projeto DELIVERY principal.

> **Uso restrito ao laboratório.** O resultado nunca deve, sozinho, bloquear acesso, suspender entregas, encerrar cadastro, reduzir remuneração ou produzir outra consequência de trabalho. Casos relevantes exigem revisão humana e canal de contestação.

## O que está implementado

- cadastro mínimo: ID, nome e últimos quatro dígitos do documento;
- captura de referência pela câmera do Android;
- selfie neutra e segundo registro com desafio ativo aleatório;
- comparação 1:1 local com estados **aprovado**, **revisão manual** e **não aprovado**;
- verificação experimental de iluminação, contraste, nitidez e mudança entre capturas;
- histórico com pontuações e metadados, sem persistir selfies;
- painel administrativo/diagnóstico, dados fictícios e exclusão integral;
- estado local cifrado por AES/GCM, com chave no Android Keystore;
- telas e documentação de privacidade/LGPD;
- testes do motor de decisão e teste de interface.

## Limites técnicos importantes

O LAB gera um vetor normalizado de luminância 16×16 a partir do recorte central da foto. Isso permite demonstrar o fluxo e os controles, mas **não equivale a um modelo biométrico de produção**. O desafio ativo usa duas capturas e mudança estrutural; ele não é um detector anti-spoof certificado. Não há detecção robusta de rosto, alinhamento por landmarks, proteção contra máscara/vídeo/tela, calibração demográfica ou avaliação de PAD conforme normas aplicáveis.

Para produção seriam necessários, no mínimo: SDK/modelo facial validado, PAD certificado, estudo de erro e viés, RIPD, base legal e governança, controles de acesso, retenção definida, acessibilidade, telemetria auditável sem dados excessivos e recurso humano efetivo.

## Executar

Requisitos: Flutter 3.47 ou compatível, Android SDK, Java 17 ou superior e um Android arm64 com câmera.

```powershell
flutter pub get
flutter test
flutter run
```

Para gerar o APK de teste arm64:

```powershell
flutter build apk --release --target-platform android-arm64
```

O APK será criado em `build/app/outputs/flutter-apk/app-release.apk`. O APK entregue foi assinado com uma chave descartável de laboratório; essa chave não acompanha o código-fonte. Use a sua própria configuração de assinatura antes de qualquer distribuição controlada.

## Roteiro de teste manual

1. Instale o APK e abra **LAB Facial Delivy**.
2. Confirme no início que o histórico exibido está marcado como fictício.
3. Em **Cadastro**, informe dados de teste, capture a referência, aceite o aviso e salve.
4. Em **Verificar**, capture a selfie neutra; faça o gesto indicado e capture novamente.
5. Execute a análise local e confira o estado, semelhança, mudança ativa e qualidade. “Mudança ativa” é a diferença entre as duas fotos, não uma confiança de prova de vida.
6. Confirme em **Histórico** que só há métricas, sem imagens.
7. Em **Admin**, confira o diagnóstico e use **Apagar todos os dados locais**.
8. Reabra o app e verifique que o cadastro foi removido.

## Estrutura

- `lib/main.dart`: interface e fluxos do protótipo;
- `lib/app_store.dart`: estado, retenção e histórico;
- `lib/decision_engine.dart`: métricas e política de decisão;
- `lib/native_bridge.dart`: contrato Flutter/Android;
- `android/.../MainActivity.kt`: câmera, extração local de características e armazenamento cifrado;
- `test/`: testes automatizados;
- `tool/run_decision_checks.dart`: verificação mínima independente do runner visual;
- `docs/`: arquitetura, privacidade e plano de testes.

Veja também [Arquitetura](docs/ARCHITECTURE.md), [Privacidade e LGPD](docs/PRIVACY_LGPD.md) e [Testes](docs/TESTING.md).
