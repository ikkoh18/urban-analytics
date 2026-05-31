import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/heatmap_point_model.dart';
import '../models/traffic_segment_model.dart';
import '../models/risk_score_model.dart';
import '../models/weather_current_model.dart';

// Web/Chrome: localhost:8000 (default)
// Android emulator: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
const _kBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

class ApiRepository {
  final _client = http.Client();

  Future<Map<String, dynamic>?> _post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_kBase$path');
    final res = await _client
        .post(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 25));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>?;
    }
    // Lança exceção com detalhes para o chamador tratar
    throw Exception('POST $path → ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final uri = Uri.parse('$_kBase$path');
      final res = await _client.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>?> _getList(String path) async {
    try {
      final uri = Uri.parse('$_kBase$path');
      final res = await _client.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List<dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  // ── Crime ────────────────────────────────────────────────────────────────

  Future<List<HeatmapPoint>> fetchHeatmapPoints(int hour) async {
    final data = await _getList('/crime/heatmap?hour=$hour');
    if (data == null) return [];
    return data.map((p) => HeatmapPoint(
      LatLng((p['lat'] as num).toDouble(), (p['lon'] as num).toDouble()),
      (p['weight'] as num).toDouble(),
    )).toList();
  }

  Future<List<HeatmapPoint>> fetchHeatmapTile({
    required int    hour,
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
  }) async {
    final data = await _getList(
      '/crime/heatmap/tile?hour=$hour'
      '&lat_min=$latMin&lat_max=$latMax'
      '&lon_min=$lonMin&lon_max=$lonMax',
    );
    if (data == null) return [];
    return data.map((p) => HeatmapPoint(
      LatLng((p['lat'] as num).toDouble(), (p['lon'] as num).toDouble()),
      (p['weight'] as num).toDouble(),
    )).toList();
  }

  Future<List<double>> fetchCrimeByHour() async {
    final data = await _getList('/crime/by-hour');
    if (data == null) return [];
    return data.map((v) => (v as num).toDouble()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchCrimeByArea() async {
    final data = await _getList('/crime/by-area');
    if (data == null) return [];
    return data.cast<Map<String, dynamic>>();
  }

  // ── Traffic ──────────────────────────────────────────────────────────────

  Future<List<TrafficSegment>> fetchTrafficSegments(int hour) async {
    final data = await _getList('/traffic/segments?hour=$hour');
    if (data == null) return [];
    return data.map((seg) {
      final rawPoints = seg['points'] as List<dynamic>;
      final points = rawPoints
          .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
          .toList();
      return TrafficSegment(
        name: seg['name'] as String,
        points: points,
        avgSpeed: (seg['avg_speed'] as num).toDouble(),
      );
    }).toList();
  }

  Future<List<double>> fetchSpeedByHour() async {
    final data = await _getList('/traffic/speed-by-hour');
    if (data == null) return [];
    return data.map((v) => (v as num).toDouble()).toList();
  }

  Future<List<double>> fetchFlowByHour() async {
    final data = await _getList('/traffic/flow-by-hour');
    if (data == null) return [];
    return data.map((v) => (v as num).toDouble()).toList();
  }

  // ── Weather ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchWeatherForMap(int hour) async {
    return _get('/weather/map?hour=$hour');
  }

  Future<WeatherCurrent> fetchWeatherCurrent(int hour) async {
    final data = await _get('/weather/current?hour=$hour');
    if (data == null) return WeatherCurrent.fallback(hour);
    return WeatherCurrent.fromJson(data);
  }

  Future<List<double>> fetchPrecipitationByHour() async {
    final data = await _get('/weather/by-hour');
    if (data == null) return [];
    final list = data['precipitation'] as List<dynamic>?;
    return list?.map((v) => (v as num).toDouble()).toList() ?? [];
  }

  // ── Risk ─────────────────────────────────────────────────────────────────

  Future<RiskScoreModel?> fetchRiskScore(String area, int hour) async {
    final data = await _get('/risk/score?area=${Uri.encodeComponent(area)}&hour=$hour');
    if (data == null) return null;
    return RiskScoreModel(
      areaName:       data['area_name'] as String,
      hour:           data['hour'] as int,
      crimeNorm:      (data['crime_norm'] as num).toDouble(),
      congestionNorm: (data['congestion_norm'] as num).toDouble(),
      riskScore:      (data['score'] as num).toDouble(),
      riskLevel:      data['risk_level'] as String,
    );
  }

  Future<List<Map<String, dynamic>>> fetchTopRiskSlots() async {
    final data = await _getList('/risk/top-slots');
    if (data == null) return [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchRiskRanking() async {
    final data = await _getList('/risk/ranking');
    if (data == null) return [];
    return data.cast<Map<String, dynamic>>();
  }

  // ── AI ───────────────────────────────────────────────────────────────────

  /// Chamada ao endpoint de chat da IA no backend.
  /// [isInitial] = true → resposta inicial ao selecionar bairro (cacheada).
  /// [isInitial] = false → resposta de chat livre (usa [history]).
  Future<String?> fetchAIChat({
    required String context,
    required String system,
    List<Map<String, String>> history = const [],
    bool isInitial = false,
  }) async {
    final data = await _post('/ai/chat', {
      'context': context,
      'system': system,
      'history': history,
      'is_initial': isInitial,
    });
    return data?['reply'] as String?;
  }

  /// Clima em tempo real via Gemini (backend). Retorna {temp_c, condition, humidity}.
  Future<Map<String, dynamic>?> fetchAIWeather(String area) async {
    return _post('/ai/weather', {'area': area});
  }

  void dispose() => _client.close();
}
