import 'package:flutter/material.dart';
import '../../core/layout/app_scaffold.dart';
import '../../core/theme/app_theme.dart';
import 'map_controller.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0,
      body: const Center(
        child: Text(
          'Mapa — em desenvolvimento',
          style: TextStyle(color: AppTheme.offwhite),
        ),
      ),
    );
  }
}
