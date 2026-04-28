import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TrafficSegment {
  final String name;
  final List<LatLng> points;
  final double avgSpeed; // mph

  const TrafficSegment({
    required this.name,
    required this.points,
    required this.avgSpeed,
  });

  Color get lineColor {
    if (avgSpeed < 15) return const Color(0xFFE24B4A); // vermelho — parado
    if (avgSpeed < 35) return const Color(0xFFF4821E); // laranja — lento
    return const Color(0xFF1E88A8);                    // azul    — fluindo
  }

  double get strokeWidth => avgSpeed < 35 ? 6.0 : 4.0;
}
