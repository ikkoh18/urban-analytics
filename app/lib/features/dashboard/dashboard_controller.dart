import 'package:flutter/foundation.dart';

class DashboardController extends ChangeNotifier {
  String selectedPeriod = 'week'; // 'day', 'week', 'month'

  void setPeriod(String period) {
    selectedPeriod = period;
    notifyListeners();
  }
}
