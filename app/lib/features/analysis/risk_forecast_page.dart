import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RiskForecastPage extends StatelessWidget {
  const RiskForecastPage({super.key});

  static const _baseRisk = {
    'Hollywood': 8.1,
    'Downtown':  8.4,
  };

  static const _weatherNotes = {
    'morning':   'Nevoeiro matinal, 18 °C',
    'afternoon': 'Ensolarado, 25 °C',
    'evening':   'Parcialmente nublado, 22 °C',
    'night':     'Limpo, 17 °C',
  };

  String _weatherForHour(int hour) {
    if (hour >= 6 && hour < 12) return _weatherNotes['morning']!;
    if (hour >= 12 && hour < 18) return _weatherNotes['afternoon']!;
    if (hour >= 18 && hour < 22) return _weatherNotes['evening']!;
    return _weatherNotes['night']!;
  }

  String _riskLevel(String zone, int hour) {
    final base = _baseRisk[zone] ?? 5.0;
    final m = (hour >= 18 && hour <= 23)
        ? 1.2
        : (hour <= 5 ? 0.7 : 1.0);
    final v = (base * m).clamp(0.0, 10.0);
    if (v >= 7) return 'Alto';
    if (v >= 4) return 'Moderado';
    return 'Baixo';
  }

  Color _riskColor(String level) {
    return switch (level) {
      'Alto'     => const Color(0xFFE24B4A),
      'Moderado' => const Color(0xFFF4821E),
      _          => const Color(0xFF4CAF92),
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hours = List.generate(6, (i) => now.add(Duration(hours: i)));

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Previsão de risco'),
        backgroundColor: AppTheme.navy,
        foregroundColor: AppTheme.offwhite,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Próximas 6 horas a partir das ${now.hour}h',
            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...hours.map((dt) {
            final h = dt.hour;
            final hwRisk = _riskLevel('Hollywood', h);
            final dtRisk = _riskLevel('Downtown', h);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.muted.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${h}h',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.wb_sunny_outlined,
                                color: AppTheme.muted, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _weatherForHour(h),
                              style: const TextStyle(
                                  color: AppTheme.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _zoneRisk('Hollywood', hwRisk)),
                        const SizedBox(width: 10),
                        Expanded(child: _zoneRisk('Downtown', dtRisk)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _zoneRisk(String zone, String level) {
    final c = _riskColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(zone,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(level,
              style: TextStyle(
                color: c,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}
