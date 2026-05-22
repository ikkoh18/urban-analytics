import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/api_repository.dart';
import '../../data/models/risk_score_model.dart';
import '../../data/models/traffic_segment_model.dart';
import '../../data/models/weather_current_model.dart';

const _kAnthropicKey =
    String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

enum AppPhase { selection, result }

enum TimePeriod { now, tonight, weekend }

// ── Coordenadas centrais LAPD ─────────────────────────────────────────────────
const _kAreaLatLng = <String, LatLng>{
  'CENTRAL':     LatLng(34.0484, -118.2468),
  'HOLLYWOOD':   LatLng(34.0928, -118.3287),
  'WILSHIRE':    LatLng(34.0638, -118.3215),
  'WEST LA':     LatLng(34.0552, -118.4426),
  'VAN NUYS':    LatLng(34.1834, -118.4494),
  'NORTHEAST':   LatLng(34.1088, -118.2006),
  'RAMPART':     LatLng(34.0677, -118.2796),
  'SOUTHWEST':   LatLng(34.0003, -118.3051),
  'HARBOR':      LatLng(33.7881, -118.2814),
  'N HOLLYWOOD': LatLng(34.1681, -118.3793),
  'MISSION':     LatLng(34.2684, -118.4385),
  'OLYMPIC':     LatLng(34.0488, -118.3141),
  'NEWTON':      LatLng(34.0185, -118.2453),
  'PACIFIC':     LatLng(33.9425, -118.4299),
  'DEVONSHIRE':  LatLng(34.2519, -118.5271),
  'FOOTHILL':    LatLng(34.2716, -118.3513),
  'HOLLENBECK':  LatLng(34.0614, -118.2029),
  'SOUTHEAST':   LatLng(33.9628, -118.2428),
  '77TH STREET': LatLng(33.9741, -118.2904),
  'TOPANGA':     LatLng(34.1959, -118.6087),
};

const _kLACenter = LatLng(34.0522, -118.2437);

String formatAreaName(String raw) => raw
    .split(' ')
    .map((w) => w.isEmpty
        ? ''
        : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
    .join(' ');

class HomeController extends ChangeNotifier {
  final _api = ApiRepository();
  final _client = http.Client();

  AppPhase phase = AppPhase.selection;
  TimePeriod timePeriod = TimePeriod.now;
  bool isPt = true;

  // ── Estado 1 ─────────────────────────────────────────────────────────────────
  bool isLoadingAreas = false;
  bool hasError = false;
  List<Map<String, dynamic>> areas = [];
  Map<String, String> riskBadges = {};
  String searchQuery = '';

  // ── Mapa (ambos os estados) ───────────────────────────────────────────────────
  List<WeightedLatLng> heatmapPoints = [];
  List<TrafficSegment> trafficSegments = [];

  // ── Estado 2 ─────────────────────────────────────────────────────────────────
  String? selectedArea;
  bool isLoadingResult = false;
  RiskScoreModel? riskScore;
  double? avgSpeed;
  WeatherCurrent? weather;
  String? aiResponse;
  bool isLoadingAI = false;

  // ── Getters ──────────────────────────────────────────────────────────────────
  int get currentHour {
    switch (timePeriod) {
      case TimePeriod.now:     return DateTime.now().hour;
      case TimePeriod.tonight: return 21;
      case TimePeriod.weekend: return 15;
    }
  }

  LatLng get areaLatLng =>
      _kAreaLatLng[selectedArea?.toUpperCase()] ?? _kLACenter;

  List<Map<String, dynamic>> get filteredAreas {
    if (searchQuery.isEmpty) return areas;
    final q = searchQuery.toLowerCase();
    return areas
        .where((a) => (a['name'] as String).toLowerCase().contains(q))
        .toList();
  }

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isPt = prefs.getBool('isPt') ?? true;

    isLoadingAreas = true;
    hasError = false;
    notifyListeners();
    try {
      areas = await _api.fetchCrimeByArea();
      debugPrint('[init] fetchCrimeByArea → ${areas.length} áreas');
      if (areas.isEmpty) {
        hasError = true;
      } else {
        _loadRiskBadgesAsync();
      }
    } catch (e) {
      debugPrint('[init] ERROR fetchCrimeByArea: $e');
      hasError = true;
    }
    isLoadingAreas = false;
    notifyListeners();
    // Carrega heatmap + tráfego em background, independente do resultado das áreas
    loadMapLayers(currentHour);
  }

  Future<void> retryInit() async {
    areas = [];
    riskBadges.clear();
    heatmapPoints = [];
    trafficSegments = [];
    await init();
  }

  Future<void> _loadRiskBadgesAsync() async {
    final hour = currentHour;
    for (final area in areas) {
      final name = area['name'] as String;
      try {
        final risk = await _api.fetchRiskScore(name, hour);
        if (risk != null) {
          riskBadges[name] = risk.riskLevel;
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  // ── Camadas do mapa ──────────────────────────────────────────────────────────
  Future<void> loadMapLayers(int hour) async {
    try {
      final results = await Future.wait([
        _api.fetchHeatmapPoints(hour),
        _api.fetchTrafficSegments(hour),
      ]);
      heatmapPoints   = results[0] as List<WeightedLatLng>;
      trafficSegments = results[1] as List<TrafficSegment>;
      notifyListeners();
    } catch (e) {
      debugPrint('[loadMapLayers] ERROR: $e');
    }
  }

  // ── Selecionar bairro ────────────────────────────────────────────────────────
  Future<void> selectArea(String area) async {
    selectedArea = area;
    isLoadingResult = true;
    aiResponse = null;
    phase = AppPhase.result;
    notifyListeners();

    final hour = currentHour;
    try {
      final results = await Future.wait([
        _api.fetchRiskScore(area, hour),
        _api.fetchSpeedByHour(),
        _api.fetchWeatherCurrent(hour),
      ]);
      riskScore    = results[0] as RiskScoreModel?;
      final speeds = results[1] as List<double>;
      weather      = results[2] as WeatherCurrent;
      avgSpeed = (speeds.isNotEmpty && hour < speeds.length)
          ? speeds[hour]
          : null;
      debugPrint('[selectArea] riskScore=${riskScore?.riskLevel} '
          'avgSpeed=$avgSpeed '
          'weather=${weather?.temperature}°C');
    } catch (e) {
      debugPrint('[selectArea] ERROR: $e');
    }

    isLoadingResult = false;
    notifyListeners();
    _loadAI();
  }

  // ── Chamada à API Anthropic ──────────────────────────────────────────────────
  Future<void> _loadAI() async {
    isLoadingAI = true;
    notifyListeners();
    try {
      aiResponse = _kAnthropicKey.isEmpty
          ? _fallback()
          : await _callClaude();
    } catch (_) {
      aiResponse = _fallback();
    }
    isLoadingAI = false;
    notifyListeners();
  }

  Future<String> _callClaude() async {
    final area  = formatAreaName(selectedArea ?? '');
    final hour  = currentHour;
    final score = riskScore?.riskScore ?? 0.0;
    final speed = avgSpeed ?? 0.0;
    final temp  = weather?.temperature ?? 20.0;
    final rain  = weather?.precipitation ?? 0.0;

    final sysPrompt = isPt
        ? 'Você é um morador experiente de Los Angeles. Responda como um local, '
          'em linguagem natural e amigável. Nunca use linguagem técnica, números '
          'de score ou termos como "risco alto". Seja direto e útil. '
          'Máximo 3 frases + 1 dica prática em destaque.'
        : 'You are an experienced Los Angeles local. Respond naturally and '
          'friendly, like a trusted neighbor. Never use technical language, '
          'score numbers, or terms like "high risk". Be direct and helpful. '
          'Max 3 sentences + 1 practical tip highlighted.';

    final userMsg = isPt
        ? 'Bairro: $area, Horário: ${hour}h, Score de risco: '
          '${score.toStringAsFixed(1)}, Velocidade média: '
          '${speed.toStringAsFixed(0)}mph, Temperatura: '
          '${temp.toStringAsFixed(0)}°C, Chuva: ${rain.toStringAsFixed(1)}mm'
        : 'Neighborhood: $area, Hour: ${hour}h, Risk score: '
          '${score.toStringAsFixed(1)}, Average speed: '
          '${speed.toStringAsFixed(0)}mph, Temperature: '
          '${temp.toStringAsFixed(0)}°C, Rain: ${rain.toStringAsFixed(1)}mm';

    final res = await _client.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': _kAnthropicKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 350,
        'system': sysPrompt,
        'messages': [
          {'role': 'user', 'content': userMsg}
        ],
      }),
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final data    = jsonDecode(res.body) as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>;
      return (content[0] as Map<String, dynamic>)['text'] as String;
    }
    return _fallback();
  }

  String _fallback() {
    final area  = formatAreaName(selectedArea ?? '');
    final level = riskScore?.riskLevel ?? 'low';
    final speed = avgSpeed ?? 40.0;
    final temp  = weather?.temperature ?? 20.0;
    final rain  = weather?.precipitation ?? 0.0;

    if (isPt) {
      final safety = level == 'high'
          ? 'Esse horário em $area costuma ter bastante movimento. Prefira áreas iluminadas e use transporte por app.'
          : level == 'medium'
              ? 'É um bom horário para visitar $area, mas fique atento ao que acontece ao redor.'
              : 'Tudo tranquilo em $area nesse horário. Ótima hora para explorar o bairro!';
      final traffic = speed < 20
          ? 'O trânsito está pesado agora.'
          : speed < 40
              ? 'Trânsito moderado, tudo fluindo.'
              : 'Vias livres, ótimo momento para se deslocar.';
      final wx = rain > 2
          ? '💡 Dica: Leve guarda-chuva — tem chuva prevista.'
          : rain > 0
              ? '💡 Dica: Pode garoar, fique de olho no tempo.'
              : '💡 Dica: Clima limpo, ${temp.round()}°C. Aproveite!';
      return '$safety $traffic\n\n$wx';
    } else {
      final safety = level == 'high'
          ? 'This time in $area can be busy. Stick to well-lit areas and use a rideshare.'
          : level == 'medium'
              ? 'It\'s a decent time to visit $area — just stay aware of your surroundings.'
              : 'All good in $area at this hour. Great time to explore the neighborhood!';
      final traffic = speed < 20
          ? 'Traffic is heavy right now.'
          : speed < 40
              ? 'Moderate traffic, things are moving.'
              : 'Roads are clear — great time to drive.';
      final wx = rain > 2
          ? '💡 Tip: Bring an umbrella — rain is expected.'
          : rain > 0
              ? '💡 Tip: Light drizzle possible, keep an eye on the weather.'
              : '💡 Tip: Clear skies, ${temp.round()}°C. Enjoy!';
      return '$safety $traffic\n\n$wx';
    }
  }

  // ── Ações ─────────────────────────────────────────────────────────────────────
  void back() {
    phase = AppPhase.selection;
    selectedArea = null;
    riskScore = null;
    avgSpeed = null;
    weather = null;
    aiResponse = null;
    // heatmapPoints e trafficSegments mantidos — continuam visíveis no mapa
    notifyListeners();
  }

  void setTimePeriod(TimePeriod p) {
    if (timePeriod == p) return;
    timePeriod = p;
    riskBadges.clear();
    _loadRiskBadgesAsync();
    loadMapLayers(currentHour);
    notifyListeners();
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    isPt = !isPt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPt', isPt);
    notifyListeners();
  }

  @override
  void dispose() {
    _api.dispose();
    _client.close();
    super.dispose();
  }
}
