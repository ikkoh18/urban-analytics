import 'package:flutter/foundation.dart';

class MapController extends ChangeNotifier {
  bool showCrimeLayer   = true;
  bool showTrafficLayer = true;
  bool showWeatherLayer = false;
  bool showRiskLayer    = false;
  int selectedHour      = 18;
  String selectedPeriod = 'Hoje';

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

  void setHour(int hour) {
    selectedHour = hour;
    notifyListeners();
  }

  void setPeriod(String period) {
    selectedPeriod = period;
    notifyListeners();
  }
}
