import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/map/map_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/assistant/assistant_page.dart';
import 'features/analysis/risk_times_page.dart';
import 'features/analysis/risk_forecast_page.dart';
import 'features/analysis/risk_score_page.dart';

void main() => runApp(const UrbanAnalyticsApp());

class UrbanAnalyticsApp extends StatelessWidget {
  const UrbanAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Urban Analytics',
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/':                       (_) => const MapPage(),
        '/dashboard':              (_) => const DashboardPage(),
        '/assistant':              (_) => const AssistantPage(),
        '/analysis/risk-times':    (_) => const RiskTimesPage(),
        '/analysis/risk-forecast': (_) => const RiskForecastPage(),
        '/analysis/risk-score':    (_) => const RiskScorePage(),
      },
    );
  }
}
