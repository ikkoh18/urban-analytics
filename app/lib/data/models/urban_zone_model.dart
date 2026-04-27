import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class UrbanZone {
  final String name;
  final LatLng position;
  final double riskScore; // 0.0 a 10.0
  final String crimeLevel; // 'Alto', 'Médio', 'Baixo'
  final String trafficLevel; // 'Lento', 'Moderado', 'Fluindo'
  final double radius; // raio do círculo em metros

  const UrbanZone({
    required this.name,
    required this.position,
    required this.riskScore,
    required this.crimeLevel,
    required this.trafficLevel,
    required this.radius,
  });

  String get riskLabel {
    if (riskScore >= 7) return 'Alto risco';
    if (riskScore >= 4) return 'Risco moderado';
    return 'Baixo risco';
  }

  Color get riskColor {
    if (riskScore >= 7) return const Color(0xFFF4821E);
    if (riskScore >= 4) return const Color(0xFF1E88A8);
    return const Color(0xFF4CAF92);
  }
}
