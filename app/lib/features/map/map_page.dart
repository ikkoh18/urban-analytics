import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:latlong2/latlong.dart';
import '../../core/layout/app_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/urban_zone_model.dart';
import '../../shared/widgets/app_drawer.dart';
import 'map_controller.dart';

// Cores canônicas do sistema de risco — reexpostas como constantes locais
// para evitar referências repetidas ao modelo.
const _kHighColor = Color(0xFFF4821E); // laranja — alto risco
const _kMedColor  = Color(0xFF1E88A8); // azul    — risco moderado
const _kLowColor  = Color(0xFF4CAF92); // verde   — baixo risco
const _kPanel     = Color(0xFF0E2A38); // fundo de chip/painel ativo

// ── MapPage ────────────────────────────────────────────────────────────────

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
    _controller.addListener(_onUpdate);
  }

  void _onUpdate() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  // Opacidade dos círculos varia com o horário selecionado (feedback visual).
  double get _circleOpacity {
    final h = _controller.selectedHour;
    if (h >= 18) return 0.50; // horário de pico
    if (h <= 5)  return 0.20; // madrugada
    return 0.35;              // horário padrão
  }

  String _diaSemana() {
    // weekday: 1=Seg … 7=Dom; mapeamos para índice 0=Dom … 6=Sáb
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return days[DateTime.now().weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0,
      drawer: const AppDrawer(currentRoute: '/'),
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(context),
          _buildLegend(),
          _buildLayerChips(),
          if (_controller.selectedZone != null)
            _buildTooltip(_controller.selectedZone!),
        ],
      ),
    );
  }

  // ── Camada 1: FlutterMap com CircleLayer + MarkerLayer ─────────────────

  Widget _buildMap() {
    final opacity = _circleOpacity;

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(34.0522, -118.2437),
        initialZoom: 11,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.urbananalytics',
        ),
        CircleLayer(
          circles: _controller.zones.map((zone) {
            return CircleMarker(
              point: zone.position,
              radius: zone.radius,
              useRadiusInMeter: true,
              color: zone.riskColor.withValues(alpha: opacity),
              borderStrokeWidth: 1.5,
              borderColor: zone.riskColor.withValues(
                alpha: (opacity + 0.35).clamp(0.0, 0.9),
              ),
            );
          }).toList(),
        ),
        MarkerLayer(
          markers: _controller.zones.map((zone) {
            final isSelected = _controller.selectedZone == zone;
            return Marker(
              point: zone.position,
              width: 104,
              height: 28,
              child: GestureDetector(
                onTap: () => _controller.selectZone(zone),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected
                        ? Border.all(color: AppTheme.teal, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    zone.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Camada 2: Barra superior (search + period chips + hour slider) ──────

  Widget _buildTopBar(BuildContext context) {
    const periods = [
      ('today', 'Hoje'),
      ('week',  'Semana'),
      ('month', 'Mês'),
    ];

    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2a. Search bar (visual — sem lógica de busca implementada)
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.muted.withValues(alpha: 0.35),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.search, color: AppTheme.muted, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Buscar bairro ou endereço...',
                  style: TextStyle(
                    color: AppTheme.muted.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2b. Period chips
          Row(
            children: periods.map(((String, String) p) {
              final isActive = _controller.selectedPeriod == p.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _controller.setPeriod(p.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? _kPanel : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppTheme.teal : AppTheme.muted,
                      ),
                    ),
                    child: Text(
                      p.$2,
                      style: TextStyle(
                        color: isActive ? AppTheme.teal : AppTheme.muted,
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // 2c. Hour slider
          Container(
            decoration: BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.muted.withValues(alpha: 0.2),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Horário de análise',
                      style: TextStyle(
                        color: AppTheme.offwhite,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${_controller.selectedHour}h',
                      style: const TextStyle(
                        color: AppTheme.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbSize: const WidgetStatePropertyAll(
                      Size.fromRadius(7),
                    ),
                    activeTrackColor: AppTheme.teal,
                    inactiveTrackColor: AppTheme.muted.withValues(alpha: 0.3),
                    thumbColor: AppTheme.teal,
                    overlayColor: AppTheme.teal.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    min: 0,
                    max: 23,
                    divisions: 23,
                    value: _controller.selectedHour.toDouble(),
                    onChanged: (v) => _controller.setHour(v.toInt()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0h',  style: TextStyle(color: AppTheme.muted, fontSize: 9)),
                    Text('6h',  style: TextStyle(color: AppTheme.muted, fontSize: 9)),
                    Text('12h', style: TextStyle(color: AppTheme.muted, fontSize: 9)),
                    Text('18h', style: TextStyle(color: AppTheme.muted, fontSize: 9)),
                    Text('23h', style: TextStyle(color: AppTheme.muted, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Camada 3: Legenda de risco ──────────────────────────────────────────

  Widget _buildLegend() {
    return Positioned(
      right: 12,
      bottom: 160,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.navy,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.muted.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NÍVEL DE RISCO',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 8,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            _legendRow(_kHighColor, 'Alto'),
            const SizedBox(height: 4),
            _legendRow(_kMedColor,  'Médio'),
            const SizedBox(height: 4),
            _legendRow(_kLowColor,  'Baixo'),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.offwhite, fontSize: 11),
        ),
      ],
    );
  }

  // ── Camada 4: Chips de camadas ──────────────────────────────────────────

  Widget _buildLayerChips() {
    final chips = [
      _ChipData('crime',   'Crime',       _kHighColor,   _controller.showCrimeLayer),
      _ChipData('traffic', 'Tráfego',     _kMedColor,    _controller.showTrafficLayer),
      _ChipData('weather', 'Clima',       AppTheme.muted, _controller.showWeatherLayer),
      _ChipData('risk',    'Risco geral', AppTheme.muted, _controller.showRiskLayer),
    ];

    return Positioned(
      bottom: 62,
      left: 12,
      right: 12,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: chips.map((chip) {
          return GestureDetector(
            onTap: () => _controller.toggleLayer(chip.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chip.active ? _kPanel : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: chip.active ? chip.color : AppTheme.muted,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: chip.active ? chip.color : AppTheme.muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    chip.label,
                    style: TextStyle(
                      color: chip.active ? chip.color : AppTheme.muted,
                      fontSize: 12,
                      fontWeight:
                          chip.active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Camada 5: Tooltip de zona selecionada ───────────────────────────────

  Widget _buildTooltip(UrbanZone zone) {
    return Positioned(
      bottom: 116,
      left: 12,
      right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.teal),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lado esquerdo — nome, contexto e camadas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    zone.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_diaSemana()} · ${_controller.selectedHour}h · camadas ativas',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Crime: ',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        zone.crimeLevel,
                        style: const TextStyle(
                          color: _kHighColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tráfego: ',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        zone.trafficLevel,
                        style: const TextStyle(
                          color: _kMedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Lado direito — botão X, score numérico, badge de risco
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _controller.selectZone(null),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  zone.riskScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppTheme.orange,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: zone.riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: zone.riskColor),
                  ),
                  child: Text(
                    zone.riskLabel,
                    style: TextStyle(
                      color: zone.riskColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dados de um chip de camada ─────────────────────────────────────────────

class _ChipData {
  final String key;
  final String label;
  final Color color;
  final bool active;

  const _ChipData(this.key, this.label, this.color, this.active);
}
