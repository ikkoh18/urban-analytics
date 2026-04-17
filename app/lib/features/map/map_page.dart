import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:latlong2/latlong2.dart';
import '../../core/layout/app_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_drawer.dart';
import 'map_controller.dart';

// Ponto de risco simulado para o heatmap
class _HeatPoint {
  final double lat;
  final double lon;
  final String name;
  final double risk;

  const _HeatPoint(this.lat, this.lon, this.name, this.risk);
}

const _heatmapPoints = [
  _HeatPoint(34.0928, -118.3287, 'Hollywood', 0.85),
  _HeatPoint(34.0407, -118.2468, 'Downtown',  0.80),
  _HeatPoint(33.9850, -118.4695, 'Venice',    0.55),
  _HeatPoint(34.1478, -118.1445, 'Pasadena',  0.30),
  _HeatPoint(33.8958, -118.2201, 'Compton',   0.90),
];

// -------------------------------------------------------

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
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _riskFill(double risk) {
    if (risk > 0.7) return Colors.red.withValues(alpha: 0.50);
    if (risk >= 0.4) return Colors.blue.withValues(alpha: 0.40);
    return Colors.green.withValues(alpha: 0.30);
  }

  Color _riskBorder(double risk) {
    if (risk > 0.7) return Colors.red.withValues(alpha: 0.80);
    if (risk >= 0.4) return Colors.blue.withValues(alpha: 0.70);
    return Colors.green.withValues(alpha: 0.60);
  }

  @override
  Widget build(BuildContext context) {
    const periods = ['Hoje', 'Semana', 'Mês'];

    return AppScaffold(
      currentIndex: 0,
      drawer: const AppDrawer(currentRoute: '/'),
      body: Stack(
        children: [
          // ── Camada 1: Mapa base ──────────────────────────────
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(34.0522, -118.2437),
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.urban_analytics_app',
              ),
              // ── Camada 2: Heatmap de pontos simulado ──────────
              CircleLayer(
                circles: _heatmapPoints
                    .map(
                      (p) => CircleMarker(
                        point: LatLng(p.lat, p.lon),
                        radius: 1500,
                        useRadiusInMeter: true,
                        color: _riskFill(p.risk),
                        borderStrokeWidth: 1.5,
                        borderColor: _riskBorder(p.risk),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),

          // ── Camada 3: Chips de período (topo) ────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: periods.map((p) {
                final isSelected = _controller.selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _controller.setPeriod(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.teal : AppTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.teal : AppTheme.muted,
                        ),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.muted,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Camada 4: Slider de horário ───────────────────────
          Positioned(
            top: 56,
            left: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Horário',
                        style: TextStyle(
                          color: AppTheme.offwhite,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${_controller.selectedHour}h',
                        style: const TextStyle(
                          color: AppTheme.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbRadius: 8,
                      overlayRadius: 14,
                      activeTrackColor: AppTheme.teal,
                      inactiveTrackColor: AppTheme.muted,
                      thumbColor: AppTheme.teal,
                      overlayColor: AppTheme.teal.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      min: 0,
                      max: 23,
                      divisions: 23,
                      value: _controller.selectedHour.toDouble(),
                      onChanged: (v) => _controller.setHour(v.round()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('0h',  style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                        Text('12h', style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                        Text('23h', style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Camada 5: Chips de camadas (bottom) ───────────────
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _LayerChip(
                  label: 'Crime',
                  layerKey: 'crime',
                  active: _controller.showCrimeLayer,
                  onTap: _controller.toggleLayer,
                ),
                const SizedBox(width: 8),
                _LayerChip(
                  label: 'Tráfego',
                  layerKey: 'traffic',
                  active: _controller.showTrafficLayer,
                  onTap: _controller.toggleLayer,
                ),
                const SizedBox(width: 8),
                _LayerChip(
                  label: 'Clima',
                  layerKey: 'weather',
                  active: _controller.showWeatherLayer,
                  onTap: _controller.toggleLayer,
                ),
                const SizedBox(width: 8),
                _LayerChip(
                  label: 'Risco',
                  layerKey: 'risk',
                  active: _controller.showRiskLayer,
                  onTap: _controller.toggleLayer,
                ),
              ],
            ),
          ),

          // ── Camada 6: Card de risco (estático) ────────────────
          Positioned(
            top: 100,
            right: 12,
            child: Container(
              width: 70,
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.orange.withValues(alpha: 0.4),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Risco',
                    style: TextStyle(color: AppTheme.muted, fontSize: 10),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '8.1',
                    style: TextStyle(
                      color: AppTheme.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Alto',
                    style: TextStyle(color: AppTheme.orange, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget auxiliar: chip de camada ────────────────────────

class _LayerChip extends StatelessWidget {
  final String label;
  final String layerKey;
  final bool active;
  final void Function(String) onTap;

  const _LayerChip({
    required this.label,
    required this.layerKey,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(layerKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.teal.withValues(alpha: 0.15) : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.teal : AppTheme.muted,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.teal : AppTheme.muted,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
