import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/urban_zone_model.dart';
import '../../data/models/traffic_segment_model.dart';

class MapController extends ChangeNotifier {
  bool showCrimeLayer   = true;
  bool showTrafficLayer = true;
  bool showWeatherLayer = false;
  bool showRiskLayer    = false;

  String selectedPeriod = 'week'; // 'today', 'week', 'month'
  int selectedHour = 18;

  UrbanZone? selectedZone;

  final List<UrbanZone> zones = const [
    UrbanZone(
      name: 'Hollywood',
      position: LatLng(34.0928, -118.3287),
      riskScore: 8.1,
      crimeLevel: 'Alto',
      trafficLevel: 'Lento',
      radius: 1200,
    ),
    UrbanZone(
      name: 'Downtown',
      position: LatLng(34.0407, -118.2468),
      riskScore: 8.4,
      crimeLevel: 'Alto',
      trafficLevel: 'Lento',
      radius: 1000,
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
    UrbanZone(
      name: 'Compton',
      position: LatLng(33.8958, -118.2201),
      riskScore: 7.6,
      crimeLevel: 'Alto',
      trafficLevel: 'Moderado',
      radius: 1100,
    ),
  ];

  // Pontos para heatmap: weight normalizado de 0.0 a 1.0 pelo riskScore.
  List<({LatLng position, double weight})> get heatmapPoints =>
      zones
          .map((z) => (position: z.position, weight: z.riskScore / 10.0))
          .toList();

  final List<TrafficSegment> trafficSegments = const [
    TrafficSegment(
      name: 'Hollywood Blvd',
      points: [
        LatLng(34.1018, -118.4430),
        LatLng(34.1016, -118.4100),
        LatLng(34.1013, -118.3800),
        LatLng(34.1011, -118.3500),
        LatLng(34.1008, -118.3200),
        LatLng(34.1003, -118.2980),
      ],
      avgSpeed: 18,
    ),
    TrafficSegment(
      name: 'Sunset Blvd',
      points: [
        LatLng(34.0885, -118.4600),
        LatLng(34.0915, -118.4000),
        LatLng(34.0936, -118.3600),
        LatLng(34.0958, -118.3200),
        LatLng(34.0832, -118.2800),
        LatLng(34.0764, -118.2510),
      ],
      avgSpeed: 25,
    ),
    TrafficSegment(
      name: 'Santa Monica Blvd',
      points: [
        LatLng(34.0743, -118.4980),
        LatLng(34.0751, -118.4500),
        LatLng(34.0752, -118.4000),
        LatLng(34.0758, -118.3600),
        LatLng(34.0760, -118.3200),
      ],
      avgSpeed: 38,
    ),
    TrafficSegment(
      name: 'I-101 Hollywood Fwy',
      points: [
        LatLng(34.0534, -118.2508),
        LatLng(34.0620, -118.2630),
        LatLng(34.0730, -118.2800),
        LatLng(34.0860, -118.3020),
        LatLng(34.0960, -118.3170),
        LatLng(34.1028, -118.3290),
      ],
      avgSpeed: 12,
    ),
    TrafficSegment(
      name: 'I-110 Harbor Fwy',
      points: [
        LatLng(33.8800, -118.2176),
        LatLng(33.9100, -118.2156),
        LatLng(33.9400, -118.2152),
        LatLng(33.9650, -118.2170),
        LatLng(33.9900, -118.2290),
        LatLng(34.0200, -118.2420),
        LatLng(34.0430, -118.2585),
      ],
      avgSpeed: 30,
    ),
  ];

  void toggleLayer(String layer) {
    switch (layer) {
      case 'crime':
        showCrimeLayer = !showCrimeLayer;
        break;
      case 'traffic':
        showTrafficLayer = !showTrafficLayer;
        break;
      case 'weather':
        showWeatherLayer = !showWeatherLayer;
        break;
      case 'risk':
        showRiskLayer = !showRiskLayer;
        break;
    }
    notifyListeners();
  }

  void setPeriod(String period) {
    selectedPeriod = period;
    notifyListeners();
  }

  void setHour(int hour) {
    selectedHour = hour;
    notifyListeners();
  }

  void selectZone(UrbanZone? zone) {
    selectedZone = zone;
    notifyListeners();
  }
}
