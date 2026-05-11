import 'package:flutter/foundation.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/urban_zone_model.dart';
import '../../data/models/traffic_segment_model.dart';
import '../../data/repositories/api_repository.dart';

class MapController extends ChangeNotifier {
  final _api = ApiRepository();

  bool showCrimeLayer   = true;
  bool showTrafficLayer = true;
  bool showWeatherLayer = false;
  bool showRiskLayer    = false;

  String selectedPeriod = 'week';
  int selectedHour = 18;

  UrbanZone? selectedZone;

  bool isLoading = false;
  bool hasRain   = false;

  // Dados carregados da API — fallback local se API indisponível
  List<WeightedLatLng>  _apiHeatmapPoints   = [];
  List<TrafficSegment>  _apiTrafficSegments = [];

  // ── Zonas (mantidas localmente — são contexto, não dados brutos) ─────────
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

  // ── Heatmap — dados reais da API ─────────────────────────────────────────

  List<WeightedLatLng> get heatmapPoints => _apiHeatmapPoints;

  // ── Segmentos de tráfego ─────────────────────────────────────────────────

  List<TrafficSegment> get trafficSegments =>
      _apiTrafficSegments.isNotEmpty ? _apiTrafficSegments : _localTrafficSegments;

  final List<TrafficSegment> _localTrafficSegments = const [
    TrafficSegment(
      name: 'Hollywood Blvd',
      points: [
        LatLng(34.1016, -118.3398), LatLng(34.1007, -118.3272),
        LatLng(34.0993, -118.3195), LatLng(34.0984, -118.3101),
        LatLng(34.0974, -118.3017), LatLng(34.0966, -118.2943),
      ],
      avgSpeed: 12,
    ),
    TrafficSegment(
      name: 'Sunset Blvd',
      points: [
        LatLng(34.0836, -118.2697), LatLng(34.0847, -118.2779),
        LatLng(34.0858, -118.2836), LatLng(34.0869, -118.2901),
        LatLng(34.0881, -118.2968),
      ],
      avgSpeed: 28,
    ),
    TrafficSegment(
      name: 'Santa Monica Blvd',
      points: [
        LatLng(34.0900, -118.3621), LatLng(34.0901, -118.3534),
        LatLng(34.0902, -118.3447), LatLng(34.0903, -118.3360),
        LatLng(34.0905, -118.3272),
      ],
      avgSpeed: 45,
    ),
    TrafficSegment(
      name: 'I-101 Hollywood Fwy',
      points: [
        LatLng(34.1013, -118.3398), LatLng(34.0897, -118.3287),
        LatLng(34.0784, -118.3013), LatLng(34.0671, -118.2836),
        LatLng(34.0558, -118.2694), LatLng(34.0518, -118.2568),
      ],
      avgSpeed: 10,
    ),
    TrafficSegment(
      name: 'I-110 Harbor Fwy',
      points: [
        LatLng(34.0558, -118.2568), LatLng(34.0231, -118.2606),
        LatLng(33.9981, -118.2683), LatLng(33.9731, -118.2761),
        LatLng(33.9358, -118.2761),
      ],
      avgSpeed: 34,
    ),
    TrafficSegment(
      name: 'I-10 Santa Monica Fwy',
      points: [
        LatLng(34.0184, -118.4912), LatLng(34.0231, -118.4352),
        LatLng(34.0275, -118.3791), LatLng(34.0319, -118.3230),
        LatLng(34.0363, -118.2764), LatLng(34.0407, -118.2468),
      ],
      avgSpeed: 8,
    ),
    TrafficSegment(
      name: 'Wilshire Blvd',
      points: [
        LatLng(34.0603, -118.4437), LatLng(34.0612, -118.4150),
        LatLng(34.0621, -118.3863), LatLng(34.0630, -118.3576),
        LatLng(34.0585, -118.3126), LatLng(34.0558, -118.2900),
      ],
      avgSpeed: 22,
    ),
    TrafficSegment(
      name: 'Vermont Ave',
      points: [
        LatLng(34.1013, -118.2919), LatLng(34.0784, -118.2919),
        LatLng(34.0558, -118.2919), LatLng(34.0275, -118.2919),
      ],
      avgSpeed: 40,
    ),
  ];

  // ── API loading ──────────────────────────────────────────────────────────

  Future<void> loadMapData(int hour) async {
    isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _api.fetchHeatmapPoints(hour),
      _api.fetchTrafficSegments(hour),
      _api.fetchWeatherForMap(hour),
    ]);

    final points   = results[0] as List<WeightedLatLng>;
    final segments = results[1] as List<TrafficSegment>;
    final weather  = results[2] as Map<String, dynamic>?;

    if (points.isNotEmpty)   _apiHeatmapPoints   = points;
    if (segments.isNotEmpty) _apiTrafficSegments = segments;
    if (weather != null)     hasRain = weather['has_rain'] as bool? ?? false;

    isLoading = false;
    notifyListeners();
  }

  // ── State ────────────────────────────────────────────────────────────────

  void toggleLayer(String layer) {
    switch (layer) {
      case 'crime':   showCrimeLayer   = !showCrimeLayer;
      case 'traffic': showTrafficLayer = !showTrafficLayer;
      case 'weather': showWeatherLayer = !showWeatherLayer;
      case 'risk':    showRiskLayer    = !showRiskLayer;
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
    loadMapData(hour); // recarrega ao mudar horário
  }

  void selectZone(UrbanZone? zone) {
    selectedZone = zone;
    notifyListeners();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
