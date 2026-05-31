import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:latlong2/latlong.dart';
import '../../core/layout/app_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/urban_zone_model.dart';
import '../../shared/widgets/app_drawer.dart';
import 'map_controller.dart';

Color _heatmapColor(double w) {
  if (w > 0.85) return const Color(0xFFE53935);
  if (w > 0.65) return const Color(0xFFFF7043);
  if (w > 0.44) return const Color(0xFFFFB300);
  if (w > 0.27) return const Color(0xFFFFEE58);
  return const Color(0xFF81C784);
}

const _kHighColor = Color(0xFFF4821E);
const _kMedColor  = Color(0xFF1E88A8);
const _kLowColor  = Color(0xFF4CAF92);
const _kPanel     = Color(0xFF0E2A38);

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
    // Carrega dados reais da API na inicialização
    _controller.loadMapData(_controller.selectedHour);
    // Lê argumento 'selectedZone' enviado pelo AssistantPage ("Ver no mapa").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['selectedZone'] != null) {
        final name = args['selectedZone'] as String;
        final zone = _controller.zones.firstWhere(
          (z) => z.name == name,
          orElse: () => _controller.zones.first,
        );
        _controller.selectZone(zone);
      }
    });
  }

  void _onUpdate() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  // ── Feedback visual de horário: opacidade das camadas de risco ─────────
  double get _circleOpacity {
    final h = _controller.selectedHour;
    if (h >= 18) return 0.50;
    if (h <= 5)  return 0.20;
    return 0.35;
  }

  String _diaSemana() {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return days[DateTime.now().weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      drawer: const AppDrawer(currentRoute: '/'),
      body: Column(
        children: [
          _buildHourSlider(context),
          Expanded(
            child: Stack(
              children: [
                _buildMap(),
                _buildPeriodChips(),
                _buildLegend(),
                _buildLayerChips(),
                if (_controller.selectedZone != null)
                  _buildTooltip(_controller.selectedZone!),
                if (_controller.isLoading)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Slider de horário — fixo abaixo do AppBar ──────────────────────────
  Widget _buildHourSlider(BuildContext context) {
    return Container(
      color: AppTheme.navy,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Horário de análise',
                style: TextStyle(color: AppTheme.offwhite, fontSize: 12),
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
              thumbSize: const WidgetStatePropertyAll(Size.fromRadius(7)),
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
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  // ── FlutterMap: heatmap de crime + tráfego + marcadores tocáveis ───────
  Widget _buildMap() {
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

        // ── Heatmap de crime com CircleMarkers em metros (escala com zoom) ──
        if (_controller.showCrimeLayer && _controller.heatmapPoints.isNotEmpty)
          CircleLayer(
            circles: _controller.heatmapPoints.map((p) => CircleMarker(
              point: p.latLng,
              radius: 150 + (p.intensity * 250),
              useRadiusInMeter: true,
              color: _heatmapColor(p.intensity).withValues(
                  alpha: 0.15 + (p.intensity * 0.25)),
              borderStrokeWidth: 0,
            )).toList(),
          ),

        // ── Linhas de tráfego estilo Google Maps ──────────────────────────
        if (_controller.showTrafficLayer)
          PolylineLayer(polylines: _buildTrafficPolylines()),

        // ── Marcadores transparentes para interatividade (sem labels) ─────
        MarkerLayer(
          markers: _controller.zones.map((zone) {
            return Marker(
              point: zone.position,
              width: 88,
              height: 88,
              child: GestureDetector(
                onTap: () => _controller.selectZone(zone),
                child: Container(color: Colors.transparent),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Gera polylines coloridas por velocidade com borda estilo Google Maps.
  List<Polyline> _buildTrafficPolylines() {
    return _controller.trafficSegments.map((seg) {
      return Polyline(
        points: seg.points,
        color: seg.lineColor,
        strokeWidth: seg.strokeWidth,
        borderColor: Colors.black45,
        borderStrokeWidth: 2.0,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      );
    }).toList();
  }

  // ── Chips de período — overlay no topo do mapa ────────────────────────
  Widget _buildPeriodChips() {
    const periods = [
      ('today', 'Hoje'),
      ('week',  'Semana'),
      ('month', 'Mês'),
    ];

    return Positioned(
      top: 8,
      left: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map(((String, String) p) {
          final isActive = _controller.selectedPeriod == p.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _controller.setPeriod(p.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _kPanel
                      : Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppTheme.teal : AppTheme.muted.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  p.$2,
                  style: TextStyle(
                    color: isActive ? AppTheme.teal : AppTheme.offwhite,
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Legenda de risco ──────────────────────────────────────────────────
  Widget _buildLegend() {
    return Positioned(
      right: 12,
      bottom: 100,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.navy,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.muted.withValues(alpha: 0.3)),
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
            _legendRow(_kMedColor, 'Médio'),
            const SizedBox(height: 4),
            _legendRow(_kLowColor, 'Baixo'),
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
        Text(label, style: const TextStyle(color: AppTheme.offwhite, fontSize: 11)),
      ],
    );
  }

  // ── Chips de camadas ──────────────────────────────────────────────────
  Widget _buildLayerChips() {
    final chips = [
      _ChipData('crime',   'Crime',       _kHighColor,    _controller.showCrimeLayer),
      _ChipData('traffic', 'Tráfego',     _kMedColor,     _controller.showTrafficLayer),
      _ChipData('weather', 'Clima',       AppTheme.muted, _controller.showWeatherLayer),
      _ChipData('risk',    'Risco geral', AppTheme.muted, _controller.showRiskLayer),
    ];

    return Positioned(
      bottom: 12,
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
                color: chip.active ? _kPanel : Colors.black.withValues(alpha: 0.45),
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
                      fontWeight: chip.active ? FontWeight.bold : FontWeight.normal,
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

  // ── Tooltip de zona selecionada ───────────────────────────────────────
  Widget _buildTooltip(UrbanZone zone) {
    return Positioned(
      bottom: 72,
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
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Crime: ',
                          style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                      Text(zone.crimeLevel,
                          style: const TextStyle(
                              color: _kHighColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      const Text('Tráfego: ',
                          style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                      Text(zone.trafficLevel,
                          style: const TextStyle(
                              color: _kMedColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _controller.selectZone(null),
                  child: const Icon(Icons.close, size: 16, color: AppTheme.muted),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

class _ChipData {
  final String key;
  final String label;
  final Color color;
  final bool active;
  const _ChipData(this.key, this.label, this.color, this.active);
}
