# Testes

## Automatizados

`test/decision_engine_test.dart` cobre:

- aprovação com alta semelhança e mudança ativa plausível;
- revisão quando as duas capturas são iguais;
- não aprovação com baixa semelhança;
- revisão obrigatória quando a qualidade é ruim.

`test/widget_test.dart` verifica a abertura do painel e a presença dos avisos de laboratório e decisão não automatizada.

Execução padrão:

```powershell
flutter test
```

Verificação mínima do motor, útil em ambiente sem runner gráfico:

```powershell
dart run tool/run_decision_checks.dart
```

## Manual no aparelho

Além do roteiro do README, testar cancelamento da câmera, repetição de captura, imagem escura, imagem desfocada, gesto ausente, cadastro substituído, exclusão de dados, reinício do app e desinstalação. Confirmar visualmente que nenhuma tentativa inconclusiva aplica consequência automática.

## Critérios para avançar além do LAB

O APK não deve avançar para piloto operacional sem testes em dispositivos reais, PAD robusto, avaliação de segurança, calibração de limiares, estudo de viés, acessibilidade, revisão de privacidade e processo humano de recurso.
