import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';

// ── Dados de zona para injeção no system prompt ────────────────────────────
const _kZoneData = {
  'Hollywood': (
    riskScore: 8.1,
    crimeLevel: 'Alto',
    trafficLevel: 'Lento',
    weather: 'Parcialmente nublado, 22 °C',
  ),
  'Downtown LA': (
    riskScore: 8.4,
    crimeLevel: 'Alto',
    trafficLevel: 'Lento',
    weather: 'Ensolarado, 25 °C',
  ),
  'Venice Beach': (
    riskScore: 5.2,
    crimeLevel: 'Médio',
    trafficLevel: 'Moderado',
    weather: 'Nevoeiro costeiro, 19 °C',
  ),
  'Compton': (
    riskScore: 7.6,
    crimeLevel: 'Alto',
    trafficLevel: 'Moderado',
    weather: 'Ensolarado, 24 °C',
  ),
};

// Mapeia nome do assistente → nome da zona no MapController
const _kZoneMap = {
  'Hollywood':   'Hollywood',
  'Downtown LA': 'Downtown',
  'Venice Beach':'Venice',
  'Compton':     'Compton',
};

enum _Step { destination, timeSlot, dimensions, response }

// ── AssistantPage ──────────────────────────────────────────────────────────

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  _Step _step = _Step.destination;
  String? _destination;
  String? _timeSlot;
  final Set<String> _dimensions = {};
  String? _response;
  bool _isLoading = false;
  bool _customMode = false;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final dest = _destination ?? _customCtrl.text.trim();
    final zd = _kZoneData[dest];

    final systemPrompt = zd != null
        ? 'O usuário quer ir para $dest às $_timeSlot. '
          'Com base nos dados históricos de 2022 a 2025: '
          'riskScore=${zd.riskScore}, crime=${zd.crimeLevel}, '
          'tráfego=${zd.trafficLevel} nesse horário, clima=${zd.weather}. '
          'Responda de forma direta e prática com no máximo 3 recomendações.'
        : 'O usuário quer ir para $dest às $_timeSlot em Los Angeles. '
          'Não temos dados históricos específicos para essa área. '
          'Forneça recomendações gerais de segurança, tráfego e clima para '
          'turistas em Los Angeles. Máximo 3 recomendações.';

    final userMsg =
        'Quero ir para $dest às $_timeSlot. Interesse: ${_dimensions.join(', ')}.';

    final text = await _callClaude(systemPrompt, userMsg);
    setState(() {
      _response = text;
      _isLoading = false;
      _step = _Step.response;
    });
  }

  Future<String> _callClaude(String system, String userMsg) async {
    const apiKey = String.fromEnvironment(
      'ANTHROPIC_API_KEY',
      defaultValue: '',
    );
    if (apiKey.isEmpty) {
      return 'Para usar o assistente, configure a chave de API Anthropic.\n\n'
          'Execute o app com:\n'
          'flutter run --dart-define=ANTHROPIC_API_KEY=sua-chave';
    }
    try {
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 400,
          'system': system,
          'messages': [
            {'role': 'user', 'content': userMsg},
          ],
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final content = (data['content'] as List)[0] as Map<String, dynamic>;
        return content['text'] as String;
      }
      return 'Erro ${res.statusCode}. Tente novamente.';
    } catch (_) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }
  }

  void _reset() {
    setState(() {
      _step = _Step.destination;
      _destination = null;
      _timeSlot = null;
      _dimensions.clear();
      _response = null;
      _isLoading = false;
      _customMode = false;
      _customCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Assistente'),
        backgroundColor: AppTheme.navy,
        foregroundColor: AppTheme.offwhite,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumb(),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final parts = <String>[];
    if (_destination != null || (_customMode && _customCtrl.text.isNotEmpty)) {
      parts.add(_destination ?? _customCtrl.text.trim());
    }
    if (_timeSlot != null) parts.add(_timeSlot!);
    if (_dimensions.isNotEmpty) parts.add(_dimensions.join(', '));
    if (parts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      children: parts
          .map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.teal.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(p,
                    style: const TextStyle(
                      color: AppTheme.teal,
                      fontSize: 11,
                    )),
              ))
          .toList(),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_step) {
      _Step.destination  => _buildDestinationStep(),
      _Step.timeSlot     => _buildTimeStep(),
      _Step.dimensions   => _buildDimensionsStep(),
      _Step.response     => _buildResponseStep(),
    };
  }

  // ── Passo 1: Destino ───────────────────────────────────────────────────
  Widget _buildDestinationStep() {
    final presets = _kZoneData.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Para onde você vai hoje?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...presets.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              label: name,
              onTap: () => setState(() {
                _destination = name;
                _customMode = false;
                _step = _Step.timeSlot;
              }),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _OptionTile(
          label: 'Outro local…',
          icon: Icons.edit_outlined,
          onTap: () => setState(() {
            _destination = null;
            _customMode = true;
          }),
        ),
        if (_customMode) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _customCtrl,
            autofocus: true,
            style: const TextStyle(color: AppTheme.offwhite),
            decoration: InputDecoration(
              hintText: 'Digite o local…',
              hintStyle: TextStyle(color: AppTheme.muted.withValues(alpha: 0.7)),
              filled: true,
              fillColor: AppTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _customCtrl.text.trim().isEmpty
                  ? null
                  : () => setState(() => _step = _Step.timeSlot),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.teal),
              child: const Text('Continuar'),
            ),
          ),
        ],
      ],
    );
  }

  // ── Passo 2: Horário ───────────────────────────────────────────────────
  Widget _buildTimeStep() {
    const slots = [
      ('Manhã', '6h–12h'),
      ('Tarde', '12h–18h'),
      ('Noite', '18h–23h'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qual horário você pretende ir?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...slots.map(
          ((String, String) s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              label: s.$1,
              subtitle: s.$2,
              onTap: () => setState(() {
                _timeSlot = '${s.$1} (${s.$2})';
                _step = _Step.dimensions;
              }),
            ),
          ),
        ),
      ],
    );
  }

  // ── Passo 3: Dimensões ────────────────────────────────────────────────
  Widget _buildDimensionsStep() {
    const dims = ['Segurança', 'Tráfego', 'Clima'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'O que você quer saber?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecione um ou mais tópicos',
          style: TextStyle(color: AppTheme.muted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ...dims.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() {
                if (_dimensions.contains(d)) {
                  _dimensions.remove(d);
                } else {
                  _dimensions.add(d);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _dimensions.contains(d)
                      ? AppTheme.teal.withValues(alpha: 0.15)
                      : AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _dimensions.contains(d)
                        ? AppTheme.teal
                        : AppTheme.muted.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _dimensions.contains(d)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _dimensions.contains(d)
                          ? AppTheme.teal
                          : AppTheme.muted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      d,
                      style: TextStyle(
                        color: _dimensions.contains(d)
                            ? Colors.white
                            : AppTheme.muted,
                        fontSize: 15,
                        fontWeight: _dimensions.contains(d)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _dimensions.isEmpty ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Consultar assistente', style: TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }

  // ── Passo 4: Resposta ──────────────────────────────────────────────────
  Widget _buildResponseStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppTheme.teal),
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.teal.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppTheme.teal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Urban Analytics AI',
                              style: TextStyle(
                                color: AppTheme.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _response ?? '',
                          style: const TextStyle(
                            color: AppTheme.offwhite,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!_isLoading) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.teal,
                    side: const BorderSide(color: AppTheme.teal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Outra pergunta'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final dest = _destination ?? _customCtrl.text.trim();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                      arguments: {
                        'selectedZone': _kZoneMap[dest] ?? dest,
                      },
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Ver no mapa'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Widget auxiliar: opção de seleção ──────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.muted.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              icon ?? Icons.location_on_outlined,
              color: AppTheme.teal,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.muted, size: 18),
          ],
        ),
      ),
    );
  }
}
