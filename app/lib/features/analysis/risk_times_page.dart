import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RiskTimesPage extends StatefulWidget {
  const RiskTimesPage({super.key});

  @override
  State<RiskTimesPage> createState() => _RiskTimesPageState();
}

typedef _Slot = ({String day, int hour, String zone, double score});

class _RiskTimesPageState extends State<RiskTimesPage> {
  static const _slots = <_Slot>[
    (day: 'Sex', hour: 22, zone: 'Downtown',  score: 9.2),
    (day: 'Sex', hour: 21, zone: 'Hollywood', score: 9.0),
    (day: 'Sáb', hour: 23, zone: 'Compton',   score: 8.8),
    (day: 'Sex', hour: 23, zone: 'Downtown',  score: 8.7),
    (day: 'Qui', hour: 20, zone: 'Hollywood', score: 8.5),
    (day: 'Sáb', hour: 22, zone: 'Downtown',  score: 8.4),
    (day: 'Sex', hour: 20, zone: 'Compton',   score: 8.2),
    (day: 'Qui', hour: 19, zone: 'Hollywood', score: 8.1),
    (day: 'Sáb', hour: 21, zone: 'Venice',    score: 6.8),
    (day: 'Sex', hour: 22, zone: 'Venice',    score: 6.5),
  ];

  String _filter = 'Todos';

  List<_Slot> get _filtered => _filter == 'Todos'
      ? _slots
      : _slots.where((s) => s.zone == _filter).toList();

  Color _scoreColor(double s) {
    if (s >= 8) return const Color(0xFFE24B4A);
    if (s >= 6) return const Color(0xFFF4821E);
    return const Color(0xFF4CAF92);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Horários de risco'),
        backgroundColor: AppTheme.navy,
        foregroundColor: AppTheme.offwhite,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtro por bairro
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Text(
                  'Bairro: ',
                  style: TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filter,
                  dropdownColor: AppTheme.card,
                  style: const TextStyle(color: AppTheme.offwhite, fontSize: 13),
                  underline: Container(
                    height: 1,
                    color: AppTheme.teal.withValues(alpha: 0.4),
                  ),
                  items: ['Todos', 'Hollywood', 'Downtown', 'Compton', 'Venice']
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) => setState(() => _filter = v ?? 'Todos'),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.card),
          // Cabeçalho da tabela
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: const [
                SizedBox(width: 36, child: Text('Dia', style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w600))),
                SizedBox(width: 36, child: Text('Hora', style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Bairro', style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w600))),
                SizedBox(width: 60, child: Text('Score', style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          ),
          // Linhas da tabela
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _filtered.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppTheme.card, height: 1),
              itemBuilder: (context, i) {
                final s = _filtered[i];
                final c = _scoreColor(s.score);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(s.day,
                            style: const TextStyle(
                                color: AppTheme.offwhite, fontSize: 13)),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('${s.hour}h',
                            style: const TextStyle(
                                color: AppTheme.offwhite, fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(s.zone,
                            style: const TextStyle(
                                color: AppTheme.offwhite, fontSize: 13)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c),
                        ),
                        child: Text(
                          s.score.toStringAsFixed(1),
                          style: TextStyle(
                              color: c,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
