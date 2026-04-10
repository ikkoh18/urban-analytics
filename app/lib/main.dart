import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/map/map_page.dart';
import 'features/dashboard/dashboard_page.dart';

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
        '/':          (_) => const MapPage(),
        '/dashboard': (_) => const DashboardPage(),
      },
    );
  }
}
