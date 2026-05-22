import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

void main() => runApp(const UrbanAnalyticsApp());

class UrbanAnalyticsApp extends StatelessWidget {
  const UrbanAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Urban Analytics',
      theme: AppTheme.darkTheme,
      home: const HomePage(),
    );
  }
}
