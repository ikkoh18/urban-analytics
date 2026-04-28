import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/urban_zone_model.dart';

class RiskScorePage extends StatelessWidget {
  const RiskScorePage({super.key});

  static const _zones = [
    UrbanZone(
      name: 'Downtown',
      position: LatLng(34.0407, -118.2468),
      riskScore: 8.4,
      crimeLevel: 'Alto',
      trafficLevel: 'Lento',
      radius: 1000,
    ),
    UrbanZone(
      name: 'Hollywood',
      position: LatLng(34.0928, -118.3287),
      riskScore: 8.1,
      crimeLevel: 'Alto',
      trafficLevel: 'Lento',
      radius: 1200,
    ),
    UrbanZone(
      name: 'Compton',
      position: LatLng(33.8958, -118.2201),
      riskScore: 7.6,
      crimeLevel: 'Alto',
      trafficLevel: 'Moderado',
      radius: 1100,
    ),
    UrbanZone(
      name: 'Venice',
      position: LatLng(33.9850, -118.4695),
      riskScore: 5.2,
      crimeLevel: 'Médio',
      trafficLevel: 'Moderado',
      radius: 900,
    ),
    UrbanZone(
      name: 'Pasadena',
      position: LatLng(34.1478, -118.1445),
      riskScore: 2.8,
      crimeLevel: 'Baixo',
      trafficLevel: 'Fluindo',
      radius: 800,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Score de risco'),
        backgroundColor: AppTheme.navy,
        foregroundColor: AppTheme.offwhite,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ranking por risco combinado',
            style: TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ..._zones.asMap().entries.map((e) {
            final rank = e.key + 1;
            final zone = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: zone.riskColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: zone.riskScore / 10.0,
                              backgroundColor: AppTheme.navy,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                zone.riskColor,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _detail('Crime', zone.crimeLevel,
                                  const Color(0xFFF4821E)),
                              const SizedBox(width: 16),
                              _detail('Tráfego', zone.trafficLevel,
                                  const Color(0xFF1E88A8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        zone.riskScore.toStringAsFixed(1),
                        style: TextStyle(
                          color: zone.riskColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _detail(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
