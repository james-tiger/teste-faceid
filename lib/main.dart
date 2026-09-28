import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_store.dart';
import 'models.dart';
import 'native_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LabFacialApp(store: AppStore(NativeDeviceBridge())..initialize()));
}

class LabFacialApp extends StatelessWidget {
  const LabFacialApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff126b5a);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LAB Facial Delivy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff5f7f6),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: Color(0xffdde4e1)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      home: LabShell(store: store),
    );
  }
}

class LabShell extends StatefulWidget {
  const LabShell({super.key, required this.store});

  final AppStore store;

  @override
  State<LabShell> createState() => _LabShellState();
}

class _LabShellState extends State<LabShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        if (!widget.store.ready) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final pages = [
          DashboardPage(store: widget.store, navigate: _go),
          RegisterPage(store: widget.store),
          VerifyPage(store: widget.store),
          HistoryPage(store: widget.store),
          AdminPage(store: widget.store),
        ];
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAB Facial Delivy',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Protótipo local • não integrado ao DELIVERY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Privacidade e LGPD',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PrivacyPage()),
                ),
                icon: const Icon(Icons.privacy_tip_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(child: pages[_index]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_add_alt),
                label: 'Cadastro',
              ),
              NavigationDestination(
                icon: Icon(Icons.face_retouching_natural),
                label: 'Verificar',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'Histórico',
              ),
              NavigationDestination(
                icon: Icon(Icons.monitor_heart_outlined),
                label: 'Admin',
              ),
            ],
          ),
        );
      },
    );
  }

  void _go(int index) => setState(() => _index = index);
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store, required this.navigate});

  final AppStore store;
  final ValueChanged<int> navigate;

  @override
  Widget build(BuildContext context) {
    final realAttempts = store.attempts
        .where((attempt) => !attempt.isDemo)
        .toList(growable: false);
    final approved = realAttempts
        .where((attempt) => attempt.status == VerificationStatus.approved)
        .length;
    final review = realAttempts
        .where((attempt) => attempt.status == VerificationStatus.manualReview)
        .length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Notice(
          icon: Icons.science_outlined,
          title: 'Ambiente de laboratório',
          text: 'Dados locais e fictícios. Nenhum resultado pode causar bloqueio, desligamento ou outra decisão de trabalho automática.',
          color: Colors.indigo,
        ),
        const SizedBox(height: 16),
        Text(
          store.courier == null
              ? 'Prepare o primeiro teste'
              : 'Olá, ${store.courier!.name.split(' ').first}',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          store.courier == null
              ? 'Cadastre uma referência antes de iniciar a verificação 1:1.'
              : 'O modelo biométrico está protegido no armazenamento privado deste aparelho.',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: 'Tentativas',
                value: '${realAttempts.length}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                label: 'Aprovadas',
                value: '$approved',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                label: 'Revisão',
                value: '$review',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        if (store.attempts.any((attempt) => attempt.isDemo)) ...[
          const SizedBox(height: 8),
          const Text(
            'Exemplos fictícios não entram nestes indicadores.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fluxo do teste',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                const _Step(
                  number: '1',
                  text: 'Cadastre dados mínimos e a foto de referência.',
                ),
                const _Step(
                  number: '2',
                  text: 'Capture selfie neutra e responda ao desafio ativo.',
                ),
                const _Step(
                  number: '3',
                  text: 'Consulte resultado, métricas e histórico auditável.',
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => navigate(store.courier == null ? 1 : 2),
                  icon: Icon(
                    store.courier == null
                        ? Icons.person_add_alt
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    store.courier == null
                        ? 'Iniciar cadastro'
                        : 'Nova verificação',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (store.startupError != null) ...[
          const SizedBox(height: 16),
          _Notice(
            icon: Icons.warning_amber,
            title: 'Aviso de inicialização',
            text: store.startupError!,
            color: Colors.orange,
          ),
        ],
      ],
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.store});

  final AppStore store;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _document = TextEditingController();
  FaceCapture? _reference;
  bool _consent = false;
  bool _busy = false;

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _document.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.store.courier;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Cadastro básico',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text('Somente os dados necessários ao teste são coletados.'),
        if (existing != null) ...[
          const SizedBox(height: 14),
          _Notice(
            icon: Icons.verified_user_outlined,
            title: 'Referência ativa: ${existing.name}',
            text:
                'ID ${existing.id} • documento final ${existing.documentLast4}. Um novo cadastro substitui a referência atual.',
            color: Colors.green,
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _id,
                    decoration: const InputDecoration(
                      labelText: 'ID do motoboy',
                      hintText: 'Ex.: MOTO-1001',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Informe um ID válido.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Informe o nome.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _document,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Últimos 4 dígitos do documento',
                      counterText: '',
                    ),
                    validator: (value) =>
                        RegExp(r'^\d{4}$').hasMatch(value ?? '')
                        ? null
                        : 'Informe exatamente 4 dígitos.',
                  ),
                  const SizedBox(height: 16),
                  _CapturePanel(
                    capture: _reference,
                    title: 'Foto facial de referência',
                    text: 'Rosto centralizado, sem capacete e com boa iluminação. A foto não será salva; somente um vetor reduzido e criptografado.',
                    buttonLabel: 'Capturar referência',
                    busy: _busy,
                    onCapture: _captureReference,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _consent,
                    onChanged: (value) =>
                        setState(() => _consent = value ?? false),
                    title: const Text(
                      'Li o aviso do LAB e autorizo este teste local.',
                    ),
                    subtitle: const Text(
                      'Consentimento revogável; exclusão disponível na tela Admin.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Salvar referência protegida'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _captureReference() async {
    setState(() => _busy = true);
    try {
      final capture = await widget.store.bridge.capturePhoto('reference');
      if (capture != null && mounted) setState(() => _reference = capture);
    } catch (error) {
      _message('Não foi possível abrir a câmera: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reference == null || !_consent) {
      _message('Capture a referência e confirme o consentimento.');
      return;
    }
    setState(() => _busy = true);
    await widget.store.registerCourier(
      id: _id.text.trim(),
      name: _name.text.trim(),
      documentLast4: _document.text,
      template: _reference!.features,
    );
    _reference = null;
    if (mounted) {
      setState(() => _busy = false);
      _message('Cadastro salvo com proteção do Android Keystore.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key, required this.store});

  final AppStore store;

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  FaceCapture? _neutral;
  FaceCapture? _challengeCapture;
  VerificationAttempt? _result;
  bool _busy = false;
  late String _challenge;

  static const _challenges = [
    'Vire levemente o rosto para a esquerda',
    'Vire levemente o rosto para a direita',
    'Incline levemente o queixo para baixo',
  ];

  @override
  void initState() {
    super.initState();
    _challenge = _challenges[math.Random().nextInt(_challenges.length)];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.store.courier == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: _Notice(
            icon: Icons.person_off_outlined,
            title: 'Cadastro necessário',
            text: 'Cadastre uma referência facial antes da verificação.',
            color: Colors.orange,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Verificação 1:1',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Comparando apenas com a referência de ${widget.store.courier!.name}.',
        ),
        const SizedBox(height: 14),
        const _Notice(
          icon: Icons.visibility_outlined,
          title: 'Prova de vida ativa — protótipo',
          text: 'Duas capturas e um gesto aleatório verificam mudança, qualidade e coerência. Não é um detector anti-spoof certificado para produção.',
          color: Colors.indigo,
        ),
        const SizedBox(height: 16),
        _CapturePanel(
          capture: _neutral,
          title: '1. Selfie neutra',
          text: 'Olhe de frente para a câmera, com expressão neutra.',
          buttonLabel: 'Capturar selfie',
          busy: _busy,
          onCapture: () => _capture(false),
        ),
        const SizedBox(height: 12),
        _CapturePanel(
          capture: _challengeCapture,
          title: '2. Desafio: $_challenge',
          text: 'Faça o movimento solicitado e capture outra foto.',
          buttonLabel: 'Capturar desafio',
          busy: _busy || _neutral == null,
          onCapture: () => _capture(true),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || _neutral == null || _challengeCapture == null
              ? null
              : _verify,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Analisar localmente'),
        ),
        if (_result != null) ...[
          const SizedBox(height: 18),
          ResultCard(attempt: _result!),
        ],
      ],
    );
  }

  Future<void> _capture(bool challenge) async {
    setState(() => _busy = true);
    try {
      final capture = await widget.store.bridge.capturePhoto(
        challenge ? 'challenge' : 'neutral',
      );
      if (capture != null && mounted) {
        setState(() {
          if (challenge) {
            _challengeCapture = capture;
          } else {
            _neutral = capture;
            _challengeCapture = null;
            _result = null;
          }
        });
      }
    } catch (error) {
      _message('Falha na captura: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    final attempt = await widget.store.verify(
      neutral: _neutral!,
      challenge: _challengeCapture!,
      challengeText: _challenge,
    );
    if (mounted)
      setState(() {
        _result = attempt;
        _busy = false;
      });
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Histórico de tentativas',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Metadados e pontuações; nenhuma selfie é mantida no histórico.',
        ),
        const SizedBox(height: 16),
        ...store.attempts.map(
          (attempt) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ResultCard(attempt: attempt, compact: true),
          ),
        ),
        if (store.attempts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Nenhuma tentativa registrada.'),
            ),
          ),
      ],
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final d = store.diagnostics;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Admin e diagnóstico',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text('Parâmetros visíveis para auditoria do protótipo.'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado do dispositivo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _KeyValue('Plataforma', '${d['platform'] ?? 'Android'}'),
                _KeyValue('Versão Android', '${d['androidVersion'] ?? '—'}'),
                _KeyValue(
                  'Arquivo protegido',
                  d['encryptedStateExists'] == true ? 'Presente' : 'Ausente',
                ),
                _KeyValue('Keystore', '${d['keystore'] ?? 'AES/GCM'}'),
                _KeyValue('Fotos persistidas', 'Não'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Limiares do LAB',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _KeyValue(
                  'Aprovação 1:1',
                  _percent(store.thresholds.approveSimilarity),
                ),
                _KeyValue(
                  'Revisão manual',
                  _percent(store.thresholds.reviewSimilarity),
                ),
                _KeyValue(
                  'Qualidade mínima',
                  _percent(store.thresholds.minimumQuality),
                ),
                _KeyValue(
                  'Mudança ativa mínima',
                  _percent(store.thresholds.minimumLiveness),
                ),
                _KeyValue(
                  'Mudança ativa máxima',
                  _percent(store.thresholds.maximumLiveness),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Heurísticas experimentais, não calibradas por estudo biométrico representativo.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: store.refreshDiagnostics,
          icon: const Icon(Icons.refresh),
          label: const Text('Atualizar diagnóstico'),
        ),
        OutlinedButton.icon(
          onPressed: store.restoreDemoHistory,
          icon: const Icon(Icons.science_outlined),
          label: const Text('Restaurar histórico fictício'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _confirmPurge(context),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Apagar todos os dados locais'),
        ),
        const SizedBox(height: 16),
        const _Notice(
          icon: Icons.gavel_outlined,
          title: 'Controle humano obrigatório',
          text: 'Resultado biométrico é apenas sinal auxiliar. Contestação e revisão humana devem estar disponíveis antes de qualquer consequência.',
          color: Colors.red,
        ),
      ],
    );
  }

  Future<void> _confirmPurge(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar dados locais?'),
        content: const Text(
          'Cadastro, modelo facial e histórico serão excluídos deste aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.clearAll();
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e LGPD')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Notice(
            icon: Icons.info_outline,
            title: 'Aviso essencial',
            text: 'Este é um protótipo técnico local. Não deve ser usado para decisões trabalhistas ou operacionais reais.',
            color: Colors.indigo,
          ),
          SizedBox(height: 16),
          _PrivacySection(
            'Finalidade',
            'Testar, de forma voluntária e controlada, um fluxo de verificação de identidade 1:1. É proibido reutilizar os dados para vigilância, identificação em massa ou finalidade incompatível.',
          ),
          _PrivacySection(
            'Dados tratados',
            'ID interno, nome, quatro últimos dígitos do documento, modelo numérico reduzido da imagem de referência e métricas das tentativas. Selfies são mantidas somente em memória durante o fluxo.',
          ),
          _PrivacySection(
            'Segurança e minimização',
            'Estado persistente cifrado com AES/GCM e chave do Android Keystore. Sem nuvem, sem analytics, sem rede e sem armazenamento das fotos neste LAB.',
          ),
          _PrivacySection(
            'Retenção e direitos',
            'Os dados permanecem apenas no aparelho até a exclusão pelo Admin ou a desinstalação. O titular pode revogar o consentimento, solicitar acesso, correção, exclusão e revisão humana.',
          ),
          _PrivacySection(
            'Decisão e contestação',
            'A saída aprovado, revisão ou não aprovado é experimental. Uma pessoa qualificada deve analisar casos relevantes, contexto, acessibilidade e possíveis vieses. Nunca aplique consequência exclusivamente automatizada.',
          ),
          _PrivacySection(
            'Antes de produção',
            'Realizar RIPD, definir controlador/operador, base legal, canal do encarregado, política de retenção, testes de viés e acurácia, acessibilidade, segurança, anti-spoof certificado e processo de recurso.',
          ),
        ],
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.attempt, this.compact = false});

  final VerificationAttempt attempt;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (attempt.status) {
      VerificationStatus.approved => (
        'Aprovado no LAB',
        Icons.check_circle_outline,
        Colors.green,
      ),
      VerificationStatus.manualReview => (
        'Revisão manual',
        Icons.person_search_outlined,
        Colors.orange,
      ),
      VerificationStatus.rejected => (
        'Não aprovado',
        Icons.cancel_outlined,
        Colors.red,
      ),
    };
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                if (attempt.isDemo) const Chip(label: Text('Fictício')),
              ],
            ),
            const SizedBox(height: 8),
            Text('${attempt.courierName} • ${_date(attempt.createdAt)}'),
            if (!compact) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Score(
                      label: 'Semelhança',
                      value: attempt.similarity,
                    ),
                  ),
                  Expanded(
                    child: _Score(
                      label: 'Mudança ativa',
                      value: attempt.liveness,
                    ),
                  ),
                  Expanded(
                    child: _Score(label: 'Qualidade', value: attempt.quality),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '“Mudança ativa” é a diferença entre as duas fotos, não uma confiança de prova de vida. Faixa experimental do LAB: 2,5% a 42,0%.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ],
            const SizedBox(height: 8),
            Text(attempt.reason, style: const TextStyle(fontSize: 12)),
            if (attempt.status != VerificationStatus.approved)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Nenhuma consequência automática é permitida.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CapturePanel extends StatelessWidget {
  const _CapturePanel({
    required this.capture,
    required this.title,
    required this.text,
    required this.buttonLabel,
    required this.busy,
    required this.onCapture,
  });
  final FaceCapture? capture;
  final String title;
  final String text;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final bytes = capture == null ? null : base64Decode(capture!.jpegBase64);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 86,
                height: 100,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: bytes == null
                    ? const Icon(Icons.face, size: 42)
                    : Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onCapture,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      capture == null ? buttonLabel : 'Capturar novamente',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String text;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color.shade800,
                ),
              ),
              const SizedBox(height: 3),
              Text(text),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final MaterialColor color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: color.shade700,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final String number;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        CircleAvatar(radius: 15, child: Text(number)),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        _percent(value),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection(this.title, this.text);
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    ),
  );
}

String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
