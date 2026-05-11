import 'package:flutter/foundation.dart';
import '../../data/repositories/api_repository.dart';

class DashboardController extends ChangeNotifier {
  final _api = ApiRepository();

  String selectedPeriod    = 'week';
  String selectedDimension = 'all';

  bool isLoading = false;

  // ── Dados de crime ───────────────────────────────────────────────────────
  List<double> crimeByHour = [
    12.0,  9.0,  7.0,  5.0,  6.0, 15.0, 28.0, 42.0,
    55.0, 62.0, 58.0, 52.0, 49.0, 53.0, 60.0, 68.0,
    72.0, 78.0, 92.0, 95.0, 88.0, 75.0, 55.0, 32.0,
  ];

  List<Map<String, dynamic>> crimeByArea = [];

  // ── Dados de tráfego ─────────────────────────────────────────────────────
  List<double> speedByHour = [
    52.0, 58.0, 60.0, 62.0, 60.0, 45.0, 32.0, 22.0,
    18.0, 28.0, 35.0, 42.0, 38.0, 35.0, 32.0, 28.0,
    22.0, 18.0, 25.0, 35.0, 42.0, 48.0, 52.0, 55.0,
  ];

  // ── Computed ─────────────────────────────────────────────────────────────
  List<double> get normalizedCrime {
    final max = crimeByHour.reduce((a, b) => a > b ? a : b);
    if (max == 0) return List.filled(24, 0.0);
    return crimeByHour.map((v) => v / max).toList();
  }

  List<double> get normalizedCongestion {
    final maxSpeed = speedByHour.reduce((a, b) => a > b ? a : b);
    if (maxSpeed == 0) return List.filled(24, 0.0);
    return speedByHour.map((v) => 1.0 - v / maxSpeed).toList();
  }

  // ── API loading ──────────────────────────────────────────────────────────
  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _api.fetchCrimeByHour(),
      _api.fetchSpeedByHour(),
      _api.fetchCrimeByArea(),
    ]);

    final crime  = results[0] as List<double>;
    final speed  = results[1] as List<double>;
    final area   = results[2] as List<Map<String, dynamic>>;

    if (crime.length == 24)  crimeByHour = crime;
    if (speed.length == 24)  speedByHour = speed;
    if (area.isNotEmpty)     crimeByArea = area;

    isLoading = false;
    notifyListeners();
  }

  void setPeriod(String period) {
    selectedPeriod = period;
    notifyListeners();
  }

  void setDimension(String dim) {
    selectedDimension = dim;
    notifyListeners();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
