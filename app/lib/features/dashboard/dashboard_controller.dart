import 'package:flutter/foundation.dart';

class DashboardController extends ChangeNotifier {
  String selectedPeriod    = 'week'; // 'today', 'week', 'month'
  String selectedDimension = 'all';  // 'all', 'crime', 'traffic', 'weather'

  // ── Dados simulados (série histórica 2022–2025) ──────────────────────
  static const crimeByHour = [
    12.0,  9.0,  7.0,  5.0,  6.0, 15.0, 28.0, 42.0,
    55.0, 62.0, 58.0, 52.0, 49.0, 53.0, 60.0, 68.0,
    72.0, 78.0, 92.0, 95.0, 88.0, 75.0, 55.0, 32.0,
  ];

  static const speedByHour = [
    52.0, 58.0, 60.0, 62.0, 60.0, 45.0, 32.0, 22.0,
    18.0, 28.0, 35.0, 42.0, 38.0, 35.0, 32.0, 28.0,
    22.0, 18.0, 25.0, 35.0, 42.0, 48.0, 52.0, 55.0,
  ];

  static const crimeByNeighborhood = <String, double>{
    'Downtown':  8.4,
    'Hollywood': 8.1,
    'Compton':   7.6,
    'Venice':    5.2,
    'Pasadena':  2.8,
  };

  // Dados normalizados para o gráfico de correlação (0–1).
  List<double> get normalizedCrime {
    const max = 95.0;
    return crimeByHour.map((v) => v / max).toList();
  }

  List<double> get normalizedCongestion {
    const maxSpeed = 62.0;
    return speedByHour.map((v) => 1.0 - v / maxSpeed).toList();
  }

  void setPeriod(String period) {
    selectedPeriod = period;
    notifyListeners();
  }

  void setDimension(String dim) {
    selectedDimension = dim;
    notifyListeners();
  }
}
