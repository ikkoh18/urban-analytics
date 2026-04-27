import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/urban_zone_model.dart';

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
