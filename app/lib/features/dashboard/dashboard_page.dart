import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/layout/app_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_drawer.dart';
import 'dashboard_controller.dart';

const _kRed    = Color(0xFFE24B4A);
const _kOrange = Color(0xFFF4821E);
const _kTeal   = Color(0xFF1E88A8);
const _kGreen  = Color(0xFF4CAF92);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = DashboardController();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dim = _ctrl.selectedDimension;
    final showCrime   = dim == 'all' || dim == 'crime';
    final showTraffic = dim == 'all' || dim == 'traffic';
    final showCorr    = dim == 'all' || dim == 'weather';

    return AppScaffold(
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 20),
            if (showCrime)   _buildCrimeBlock(),
            if (showTraffic) _buildTrafficBlock(),
            if (showCorr)    _buildCorrelationsBlock(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Filtros de período e dimensão ────────────────────────────────────
  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Período', style: TextStyle(color: AppTheme.muted, fontSize: 11, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        _chipRow(
          options: const [('today', 'Hoje'), ('week', 'Semana'), ('month', 'Mês')],
          selected: _ctrl.selectedPeriod,
          onSelect: _ctrl.setPeriod,
          activeColor: AppTheme.teal,
        ),
        const SizedBox(height: 12),
        const Text('Dimensão', style: TextStyle(color: AppTheme.muted, fontSize: 11, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        _chipRow(
          options: const [
            ('all',     'Todos'),
            ('crime',   'Crime'),
            ('traffic', 'Tráfego'),
            ('weather', 'Clima'),
          ],
          selected: _ctrl.selectedDimension,
          onSelect: _ctrl.setDimension,
          activeColor: _kOrange,
        ),
      ],
    );
  }

  Widget _chipRow({
    required List<(String, String)> options,
    required String selected,
    required void Function(String) onSelect,
    required Color activeColor,
  }) {
    return Wrap(
      spacing: 8,
      children: options.map((o) {
        final isActive = selected == o.$1;
        return GestureDetector(
          onTap: () => onSelect(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.15)
                  : AppTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? activeColor : AppTheme.muted.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              o.$2,
              style: TextStyle(
                color: isActive ? activeColor : AppTheme.muted,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Bloco de Crime ───────────────────────────────────────────────────
  Widget _buildCrimeBlock() {
    Color barColor(double v) {
      if (v > 70) return _kRed;
      if (v > 40) return _kOrange;
      return _kTeal;
    }

    return _block(
      title: 'Crime por hora do dia',
      children: [
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(24, (i) {
                final v = DashboardController.crimeByHour[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: v,
                      color: barColor(v),
                      width: 8,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(2),
                      ),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 18,
                    getTitlesWidget: (v, _) {
                      final h = v.toInt();
                      if (h % 6 == 0 || h == 23) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${h}h',
                              style: const TextStyle(
                                  color: AppTheme.muted, fontSize: 9)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              maxY: 110,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _kRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Pico: 19h–21h · média 92 ocorrências/hora',
              style: TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Top bairros por volume de crime',
          style: TextStyle(
            color: AppTheme.offwhite,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...DashboardController.crimeByNeighborhood.entries.map((e) {
          final c = e.value >= 7.5 ? _kRed : (e.value >= 5 ? _kOrange : _kGreen);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(e.key,
                      style: const TextStyle(
                          color: AppTheme.offwhite, fontSize: 12)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / 10.0,
                      backgroundColor: AppTheme.card,
                      valueColor: AlwaysStoppedAnimation<Color>(c),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  e.value.toStringAsFixed(1),
                  style: TextStyle(
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Bloco de Tráfego ─────────────────────────────────────────────────
  Widget _buildTrafficBlock() {
    Color barColor(double v) {
      if (v < 35) return _kRed;
      if (v < 55) return _kOrange;
      return _kGreen;
    }

    return _block(
      title: 'Velocidade média por hora',
      children: [
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(24, (i) {
                final v = DashboardController.speedByHour[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: v,
                      color: barColor(v),
                      width: 8,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(2),
                      ),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 18,
                    getTitlesWidget: (v, _) {
                      final h = v.toInt();
                      if (h % 6 == 0 || h == 23) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${h}h',
                              style: const TextStyle(
                                  color: AppTheme.muted, fontSize: 9)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              maxY: 70,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: _kRed, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text(
              'Pico de congestionamento: 7h–9h e 17h–19h',
              style: TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _kOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.water_drop_outlined, color: _kTeal, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Chuva reduz velocidade média em 40%',
                  style: TextStyle(color: AppTheme.offwhite, fontSize: 12),
                ),
              ),
              const Icon(Icons.arrow_downward, color: _kOrange, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bloco de Correlações ─────────────────────────────────────────────
  Widget _buildCorrelationsBlock() {
    final nc = _ctrl.normalizedCrime;
    final nt = _ctrl.normalizedCongestion;

    return _block(
      title: 'Relações entre dimensões',
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'Chuva vs velocidade\n(Spearman)',
                value: '-0.62',
                valueColor: _kOrange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                label: 'Horas crime +\ntráfego críticos',
                value: '7',
                valueColor: _kRed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                label: 'Maior risco\ncombinado',
                value: 'Downtown',
                valueColor: _kRed,
                smallValue: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _legendDot(_kOrange, 'Crime'),
            const SizedBox(width: 12),
            _legendDot(_kTeal, 'Congestionamento'),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    24,
                    (i) => FlSpot(i.toDouble(), nc[i]),
                  ),
                  isCurved: true,
                  color: _kOrange,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: List.generate(
                    24,
                    (i) => FlSpot(i.toDouble(), nt[i]),
                  ),
                  isCurved: true,
                  color: _kTeal,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 18,
                    getTitlesWidget: (v, _) {
                      final h = v.toInt();
                      if (h % 6 == 0 || h == 23) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${h}h',
                              style: const TextStyle(
                                  color: AppTheme.muted, fontSize: 9)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              minX: 0,
              maxX: 23,
              minY: 0,
              maxY: 1.15,
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  Widget _block({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.muted.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.offwhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required Color valueColor,
    bool smallValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.muted.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: smallValue ? 14 : 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 9,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 10)),
      ],
    );
  }
}
