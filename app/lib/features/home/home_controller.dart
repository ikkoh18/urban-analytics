import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/heatmap_point_model.dart';
import '../../data/repositories/api_repository.dart';
import '../../data/models/risk_score_model.dart';
import '../../data/models/traffic_segment_model.dart';
import '../../data/models/weather_current_model.dart';


enum AppPhase { selection, result }

enum DayType { weekday, weekend }

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

// ── Bairros turísticos ────────────────────────────────────────────────────────
final _kTouristAreas = <Map<String, dynamic>>[
  {'name': 'Beverly Hills',          'lat': 34.0736, 'lng': -118.4004, 'lapd': 'WILSHIRE'},
  {'name': 'Santa Monica',           'lat': 34.0195, 'lng': -118.4912, 'lapd': 'PACIFIC'},
  {'name': 'Venice Beach',           'lat': 33.9850, 'lng': -118.4695, 'lapd': 'PACIFIC'},
  {'name': 'Hollywood',              'lat': 34.0928, 'lng': -118.3287, 'lapd': 'HOLLYWOOD'},
  {'name': 'Koreatown',              'lat': 34.0580, 'lng': -118.3020, 'lapd': 'WILSHIRE'},
  {'name': 'Silver Lake',            'lat': 34.0869, 'lng': -118.2698, 'lapd': 'NORTHEAST'},
  {'name': 'Malibu',                 'lat': 34.0259, 'lng': -118.7798, 'lapd': 'PACIFIC'},
  {'name': 'Downtown Arts District', 'lat': 34.0407, 'lng': -118.2348, 'lapd': 'CENTRAL'},
];

const _kLACenter = LatLng(34.0522, -118.2437);

String formatAreaName(String raw) => raw
    .split(' ')
    .map((w) => w.isEmpty
        ? ''
        : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
    .join(' ');

class HomeController extends ChangeNotifier {
  final _api = ApiRepository();

  AppPhase phase    = AppPhase.selection;
  DayType  dayType  = DayType.weekday;
  int  selectedHour = DateTime.now().hour;
  bool isNowMode    = true;
  bool isPt         = true;

  // ── Estado 1 ─────────────────────────────────────────────────────────────────
  bool isLoadingAreas = false;
  bool hasError       = false;
  List<Map<String, dynamic>> areas = [];
  Map<String, String> riskBadges   = {};
  String searchQuery = '';

  // ── Mapa (ambos os estados) ───────────────────────────────────────────────────
  List<HeatmapPoint>   heatmapPoints        = [];
  List<HeatmapPoint>   visibleHeatmapPoints = [];
  List<TrafficSegment> trafficSegments      = [];
  bool showHeatmap = true;
  bool showTraffic = true;

  void toggleHeatmap() { showHeatmap = !showHeatmap; notifyListeners(); }
  void toggleTraffic()  { showTraffic  = !showTraffic;  notifyListeners(); }

  // ── Estado 2 ─────────────────────────────────────────────────────────────────
  String?        selectedArea;
  bool           isLoadingResult = false;
  RiskScoreModel? riskScore;
  double?         avgSpeed;
  WeatherCurrent? weather;
  String?         aiResponse;
  bool            isLoadingAI = false;

  // ── Clima em tempo real (Gemini) ──────────────────────────────────────────────
  double? geminiTempC;
  String? geminiCondition;   // ex: "Sunny", "Partly Cloudy"
  bool    isLoadingGeminiWeather = false;

  // ── Chat ─────────────────────────────────────────────────────────────────────
  List<Map<String, String>> chatHistory = [];
  bool    isChatLoading = false;
  String? _contextMsg;

  // ── Getters ──────────────────────────────────────────────────────────────────
  int get currentHour => isNowMode ? DateTime.now().hour : selectedHour;

  List<Map<String, dynamic>> get touristAreas => _kTouristAreas;

  LatLng get areaLatLng {
    for (final t in _kTouristAreas) {
      if (t['name'] == selectedArea) {
        return LatLng(
          (t['lat'] as num).toDouble(),
          (t['lng'] as num).toDouble(),
        );
      }
    }
    return _kAreaLatLng[selectedArea?.toUpperCase()] ?? _kLACenter;
  }

  List<Map<String, dynamic>> get filteredAreas {
    if (searchQuery.isEmpty) return areas;
    final q = searchQuery.toLowerCase();
    return areas
        .where((a) => (a['name'] as String).toLowerCase().contains(q))
        .toList();
  }

  /// Retorna a área LAPD de referência para cálculo de risco.
  /// Para bairros turísticos usa o campo 'lapd'; para áreas LAPD retorna o
  /// próprio nome.
  String _riskAreaFor(String name) {
    for (final t in _kTouristAreas) {
      if (t['name'] == name) return t['lapd'] as String;
    }
    return name;
  }

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isPt = prefs.getBool('isPt') ?? true;

    isLoadingAreas = true;
    hasError       = false;
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
    loadMapLayers(currentHour);
  }

  Future<void> retryInit() async {
    areas = [];
    riskBadges.clear();
    heatmapPoints   = [];
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
    // Bairros turísticos herdam o badge da área LAPD de referência —
    // já carregado pelo loop acima; não é necessária chamada extra.
  }

  // ── Camadas do mapa ──────────────────────────────────────────────────────────
  Future<void> loadMapLayers(int hour) async {
    try {
      final results = await Future.wait([
        _api.fetchHeatmapPoints(hour),
        _api.fetchTrafficSegments(hour),
      ]);
      heatmapPoints        = results[0] as List<HeatmapPoint>;
      visibleHeatmapPoints = heatmapPoints; // inicializa com dados completos
      trafficSegments      = results[1] as List<TrafficSegment>;
      notifyListeners();
    } catch (e) {
      debugPrint('[loadMapLayers] ERROR: $e');
    }
  }

  /// Recarrega o heatmap para o bounding box visível no mapa.
  /// zoom < 11 → usa dados completos (visão geral de LA)
  /// zoom >= 11 → busca apenas pontos da área visível + margem de 20%
  Future<void> loadHeatmapTile({
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
    required double zoom,
  }) async {
    if (zoom < 11.0) {
      visibleHeatmapPoints = heatmapPoints;
      notifyListeners();
      return;
    }
    try {
      final latPad = (latMax - latMin) * 0.2;
      final lonPad = (lonMax - lonMin) * 0.2;
      visibleHeatmapPoints = await _api.fetchHeatmapTile(
        hour:   currentHour,
        latMin: latMin - latPad,
        latMax: latMax + latPad,
        lonMin: lonMin - lonPad,
        lonMax: lonMax + lonPad,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[loadHeatmapTile] ERROR: $e');
    }
  }

  // ── Selecionar bairro ────────────────────────────────────────────────────────
  Future<void> selectArea(String area) async {
    selectedArea   = area;
    isLoadingResult = true;
    aiResponse     = null;
    chatHistory    = [];
    _contextMsg    = null;
    geminiTempC    = null;
    geminiCondition = null;
    phase          = AppPhase.result;
    notifyListeners();

    final hour     = currentHour;
    final riskArea = _riskAreaFor(area);

    try {
      final results = await Future.wait([
        _api.fetchRiskScore(riskArea, hour),
        _api.fetchSpeedByHour(),
        _api.fetchWeatherCurrent(hour),
      ]);
      riskScore       = results[0] as RiskScoreModel?;
      final speeds    = results[1] as List<double>;
      weather         = results[2] as WeatherCurrent;
      avgSpeed = (speeds.isNotEmpty && hour < speeds.length)
          ? speeds[hour]
          : null;
      debugPrint('[selectArea] riskArea=$riskArea riskScore=${riskScore?.riskLevel} '
          'avgSpeed=$avgSpeed weather=${weather?.temperature}°C');
    } catch (e) {
      debugPrint('[selectArea] ERROR: $e');
    }

    isLoadingResult = false;
    notifyListeners();
    // Carrega IA e clima em tempo real em paralelo
    _loadAI();
    _fetchGeminiWeather(area);
  }

  // ── Contexto para a IA ───────────────────────────────────────────────────────
  String _buildContextMsg() {
    final area  = formatAreaName(selectedArea ?? '');
    final hour  = currentHour;
    final level = riskScore?.riskLevel ?? 'low';
    final speed = avgSpeed ?? 0.0;
    final temp  = weather?.temperature ?? 20.0;
    final rain  = weather?.precipitation ?? 0.0;

    final dayStr = dayType == DayType.weekend
        ? (isPt ? 'fim de semana' : 'weekend')
        : (isPt ? 'dia de semana' : 'weekday');

    final safetyLabel = switch (level) {
      'high'   => isPt ? 'alto'     : 'high',
      'medium' => isPt ? 'moderado' : 'moderate',
      _        => isPt ? 'baixo'    : 'low',
    };
    final trafficLabel = speed < 20
        ? (isPt ? 'parado'  : 'stopped')
        : speed < 40
            ? (isPt ? 'lento'   : 'slow')
            : (isPt ? 'fluindo' : 'flowing');

    final rainPart = rain > 0
        ? (isPt
            ? ', Chuva: ${rain.toStringAsFixed(1)}mm'
            : ', Rain: ${rain.toStringAsFixed(1)}mm')
        : '';

    return isPt
        ? 'Bairro: $area, Horário: ${hour}h, Dia: $dayStr, '
          'Nível de segurança: $safetyLabel, Trânsito: $trafficLabel, '
          'Temperatura: ${temp.toStringAsFixed(0)}°C$rainPart'
        : 'Neighborhood: $area, Hour: ${hour}h, Day: $dayStr, '
          'Safety level: $safetyLabel, Traffic: $trafficLabel, '
          'Temperature: ${temp.toStringAsFixed(0)}°C$rainPart';
  }

  String _sysPrompt() => isPt
      ? 'Você é um morador experiente de Los Angeles. Responda como um local, '
        'em linguagem natural e amigável. Nunca use linguagem técnica, números '
        'de score ou termos como "risco alto". Seja direto e útil. '
        'Máximo 3 frases + 1 dica prática em destaque.'
      : 'You are an experienced Los Angeles local. Respond naturally and '
        'friendly, like a trusted neighbor. Never use technical language, '
        'score numbers, or terms like "high risk". Be direct and helpful. '
        'Max 3 sentences + 1 practical tip highlighted.';

  // ── Chamada à IA via backend ──────────────────────────────────────────────────
  Future<void> _loadAI() async {
    isLoadingAI = true;
    chatHistory = [];
    _contextMsg = _buildContextMsg();
    notifyListeners();

    String response;
    try {
      final reply = await _api.fetchAIChat(
        context: _contextMsg!,
        system: _sysPrompt(),
        isInitial: true,
      );
      response = reply ?? _fallback();
    } catch (_) {
      response = _fallback();
    }

    chatHistory = [{'role': 'assistant', 'content': response}];
    aiResponse  = response;
    isLoadingAI = false;
    notifyListeners();
  }

  // ── Clima em tempo real via backend ──────────────────────────────────────────
  Future<void> _fetchGeminiWeather(String area) async {
    isLoadingGeminiWeather = true;
    notifyListeners();

    try {
      final data = await _api.fetchAIWeather(formatAreaName(area));
      if (data != null) {
        geminiTempC     = (data['temp_c'] as num?)?.toDouble();
        geminiCondition = data['condition'] as String?;
        debugPrint('[ai weather] ${geminiTempC}°C · $geminiCondition');
      }
    } catch (e) {
      debugPrint('[ai weather] ERROR: $e');
    }

    isLoadingGeminiWeather = false;
    notifyListeners();
  }

  // ── Chat livre ───────────────────────────────────────────────────────────────
  Future<void> sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;

    chatHistory = List<Map<String, String>>.from(chatHistory)
      ..add({'role': 'user', 'content': text});
    isChatLoading = true;
    notifyListeners();

    String reply;
    try {
      final result = await _api.fetchAIChat(
        context: _contextMsg ?? _buildContextMsg(),
        system: _sysPrompt(),
        history: chatHistory,
      );
      reply = result ??
          (isPt
              ? 'Não consegui responder agora. Tente novamente.'
              : "Couldn't respond right now. Please try again.");
    } catch (e) {
      debugPrint('[chat] ERROR: $e');
      reply = isPt
          ? 'Não consegui responder agora. Tente novamente.'
          : "Couldn't respond right now. Please try again.";
    }

    chatHistory = List<Map<String, String>>.from(chatHistory)
      ..add({'role': 'assistant', 'content': reply});
    isChatLoading = false;
    notifyListeners();
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
              ? "It's a decent time to visit $area — just stay aware of your surroundings."
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
    phase           = AppPhase.selection;
    selectedArea    = null;
    riskScore       = null;
    avgSpeed        = null;
    weather         = null;
    aiResponse      = null;
    chatHistory     = [];
    _contextMsg     = null;
    geminiTempC     = null;
    geminiCondition = null;
    // heatmapPoints e trafficSegments mantidos — continuam visíveis no mapa
    notifyListeners();
  }

  void setDayType(DayType d) {
    if (dayType == d) return;
    dayType = d;
    riskBadges.clear();
    _loadRiskBadgesAsync();
    loadMapLayers(currentHour);
    notifyListeners();
  }

  void setHour(int h) {
    selectedHour = h;
    isNowMode    = false;
    riskBadges.clear();
    _loadRiskBadgesAsync();
    loadMapLayers(h);
    notifyListeners();
  }

  void setNow() {
    isNowMode = true;
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
    super.dispose();
  }
}
