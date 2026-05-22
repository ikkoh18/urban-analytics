import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/risk_score_model.dart';
import '../../data/models/weather_current_model.dart';
import 'home_controller.dart';

const _kLACenter = LatLng(34.0522, -118.2437);

// ══════════════════════════════════════════════════════════════════════════════
// HOME PAGE
// ══════════════════════════════════════════════════════════════════════════════

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _ctrl = HomeController();
  late final AnimatedMapController _animatedMapCtrl;
  final _searchCtrl = TextEditingController();
  late final AnimationController _pulseCtrl;
  bool _isFullscreen = false;

  // Controle de animação — anima só quando fase ou área muda
  AppPhase? _prevPhase;
  String? _prevArea;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animatedMapCtrl = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOut,
    );
    _ctrl.addListener(_onUpdate);
    _ctrl.init();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});

    final phase = _ctrl.phase;
    final area  = _ctrl.selectedArea;

    if (phase != _prevPhase || area != _prevArea) {
      _prevPhase = phase;
      _prevArea  = area;
      if (phase == AppPhase.result) {
        _animatedMapCtrl.animateTo(dest: _ctrl.areaLatLng, zoom: 13.0);
      } else {
        _animatedMapCtrl.animateTo(dest: _kLACenter, zoom: 10.0);
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _animatedMapCtrl.dispose();
    _ctrl.removeListener(_onUpdate);
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleFullscreen() => setState(() => _isFullscreen = !_isFullscreen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Column(
          children: [
            _AppHeader(ctrl: _ctrl),
            Expanded(
              child: _isFullscreen
                  ? _FullscreenMap(
                      ctrl: _ctrl,
                      mapCtrl: _animatedMapCtrl.mapController,
                      pulseAnim: _pulseCtrl,
                      onExit: _toggleFullscreen,
                    )
                  : Column(
                      children: [
                        _MapSection(
                          ctrl: _ctrl,
                          mapCtrl: _animatedMapCtrl.mapController,
                          pulseAnim: _pulseCtrl,
                          onFullscreen: _toggleFullscreen,
                        ),
                        if (_ctrl.phase == AppPhase.result)
                          _SubHeader(ctrl: _ctrl),
                        Expanded(
                          child: _ctrl.phase == AppPhase.selection
                              ? _SelectionContent(
                                  ctrl: _ctrl,
                                  searchCtrl: _searchCtrl,
                                )
                              : _ResultContent(
                                  ctrl: _ctrl,
                                  pulseAnim: _pulseCtrl,
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP HEADER
// ══════════════════════════════════════════════════════════════════════════════

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.navy,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
            ),
            child: const Icon(Icons.map_outlined, color: AppTheme.teal, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Urban ',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Analytics',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.teal,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'System · Los Angeles',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: ctrl.toggleLanguage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ctrl.isPt ? 'EN' : 'PT',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MAPA PERSISTENTE — heatmap + tráfego sempre ativos
// ══════════════════════════════════════════════════════════════════════════════

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.ctrl,
    required this.mapCtrl,
    required this.pulseAnim,
    required this.onFullscreen,
  });
  final HomeController ctrl;
  final MapController mapCtrl;
  final Animation<double> pulseAnim;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    final isResult = ctrl.phase == AppPhase.result;

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapCtrl,
            options: const MapOptions(
              initialCenter: _kLACenter,
              initialZoom: 10.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.urban.analytics',
              ),
              if (ctrl.heatmapPoints.isNotEmpty)
                HeatMapLayer(
                  heatMapDataSource:
                      InMemoryHeatMapDataSource(data: ctrl.heatmapPoints),
                  heatMapOptions: HeatMapOptions(
                    gradient: HeatMapOptions.defaultGradient,
                    minOpacity: 0.35,
                    radius: 28,
                  ),
                ),
              if (ctrl.trafficSegments.isNotEmpty)
                PolylineLayer(
                  polylines: ctrl.trafficSegments
                      .map((seg) => Polyline(
                            points: seg.points,
                            color: seg.lineColor,
                            strokeWidth: seg.strokeWidth,
                          ))
                      .toList(),
                ),
            ],
          ),
          // Gradiente base
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.navy.withOpacity(0), AppTheme.navy],
                ),
              ),
            ),
          ),
          // Badge de localização
          Positioned(
            bottom: 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.navy.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, __) => Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.teal
                            .withOpacity(0.5 + 0.5 * pulseAnim.value),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.teal
                                .withOpacity(0.4 * pulseAnim.value),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isResult
                        ? formatAreaName(ctrl.selectedArea ?? '')
                        : 'Los Angeles, CA',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          // Botão fullscreen
          Positioned(
            top: 10,
            right: 10,
            child: _FullscreenButton(onTap: onFullscreen),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MAPA FULLSCREEN
// ══════════════════════════════════════════════════════════════════════════════

class _FullscreenMap extends StatelessWidget {
  const _FullscreenMap({
    required this.ctrl,
    required this.mapCtrl,
    required this.pulseAnim,
    required this.onExit,
  });
  final HomeController ctrl;
  final MapController mapCtrl;
  final Animation<double> pulseAnim;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final isResult = ctrl.phase == AppPhase.result;
    final s = ctrl.isPt;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapCtrl,
          options: MapOptions(
            initialCenter: isResult ? ctrl.areaLatLng : _kLACenter,
            initialZoom: isResult ? 13.0 : 10.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.urban.analytics',
            ),
            if (ctrl.heatmapPoints.isNotEmpty)
              HeatMapLayer(
                heatMapDataSource:
                    InMemoryHeatMapDataSource(data: ctrl.heatmapPoints),
                heatMapOptions: HeatMapOptions(
                  gradient: HeatMapOptions.defaultGradient,
                  minOpacity: 0.4,
                  radius: 30,
                ),
              ),
            if (ctrl.trafficSegments.isNotEmpty)
              PolylineLayer(
                polylines: ctrl.trafficSegments
                    .map((seg) => Polyline(
                          points: seg.points,
                          color: seg.lineColor,
                          strokeWidth: seg.strokeWidth,
                        ))
                    .toList(),
              ),
          ],
        ),
        // Gradiente topo
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.navy.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
        ),
        // Botão sair fullscreen
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: onExit,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.navy.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fullscreen_exit,
                      color: AppTheme.teal, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    s ? 'Sair' : 'Exit',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppTheme.teal),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Gradiente base
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppTheme.navy.withOpacity(0.75), Colors.transparent],
              ),
            ),
          ),
        ),
        // Badge localização
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.navy.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: pulseAnim,
                  builder: (_, __) => Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.teal
                          .withOpacity(0.5 + 0.5 * pulseAnim.value),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.teal
                              .withOpacity(0.4 * pulseAnim.value),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isResult
                      ? formatAreaName(ctrl.selectedArea ?? '')
                      : 'Los Angeles, CA',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        // Badge período
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
            ),
            child: Text(
              _timeLabel(ctrl, s),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.teal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _timeLabel(HomeController c, bool pt) {
    return switch (c.timePeriod) {
      TimePeriod.now     => pt ? 'Agora · ${c.currentHour}h'   : 'Now · ${c.currentHour}h',
      TimePeriod.tonight => pt ? 'Esta noite · 21h'            : 'Tonight · 9 PM',
      TimePeriod.weekend => pt ? 'Fim de semana · 15h'         : 'Weekend · 3 PM',
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUB-HEADER (ESTADO 2) — back + nome do bairro + horário
// ══════════════════════════════════════════════════════════════════════════════

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final s = ctrl.isPt;
    final timeLabel = switch (ctrl.timePeriod) {
      TimePeriod.now     => s ? 'Agora · ${ctrl.currentHour}h' : 'Now · ${ctrl.currentHour}h',
      TimePeriod.tonight => s ? 'Esta noite · 21h'             : 'Tonight · 9 PM',
      TimePeriod.weekend => s ? 'Fim de semana · 15h'          : 'Weekend · 3 PM',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.navy,
        border:
            Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: ctrl.back,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new,
                    color: AppTheme.teal, size: 14),
                const SizedBox(width: 4),
                Text(
                  s ? 'Voltar' : 'Back',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppTheme.teal),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              formatAreaName(ctrl.selectedArea ?? ''),
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeLabel,
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ESTADO 1 — chips + busca + grid de bairros
// ══════════════════════════════════════════════════════════════════════════════

class _SelectionContent extends StatelessWidget {
  const _SelectionContent(
      {required this.ctrl, required this.searchCtrl});
  final HomeController ctrl;
  final TextEditingController searchCtrl;

  @override
  Widget build(BuildContext context) {
    final s = ctrl.isPt;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimeChips(ctrl: ctrl),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              controller: searchCtrl,
              onChanged: ctrl.setSearchQuery,
              style:
                  GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    s ? 'Buscar bairro...' : 'Search neighborhood...',
                hintStyle: GoogleFonts.dmSans(
                    color: Colors.white30, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.white30, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            s ? 'BAIRROS POPULARES' : 'POPULAR NEIGHBORHOODS',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.35),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          if (ctrl.isLoadingAreas)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.teal),
              ),
            )
          else if (ctrl.hasError)
            _ErrorBlock(ctrl: ctrl)
          else
            _NeighborhoodGrid(ctrl: ctrl),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ESTADO 2 — cards de risco/trânsito/clima + guia IA
// ══════════════════════════════════════════════════════════════════════════════

class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.ctrl, required this.pulseAnim});
  final HomeController ctrl;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoadingResult) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.teal),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(ctrl: ctrl),
          const SizedBox(height: 20),
          _GuideBlock(ctrl: ctrl, pulseAnim: pulseAnim),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPONENTES COMPARTILHADOS
// ══════════════════════════════════════════════════════════════════════════════

class _FullscreenButton extends StatelessWidget {
  const _FullscreenButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.navy.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child:
            const Icon(Icons.fullscreen, color: Colors.white70, size: 18),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final s = ctrl.isPt;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.red.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: Colors.white38, size: 36),
          const SizedBox(height: 12),
          Text(
            s
                ? 'Não foi possível carregar os bairros.\nVerifique sua conexão.'
                : 'Could not load neighborhoods.\nCheck your connection.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: Colors.white54, height: 1.5),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: ctrl.retryInit,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                s ? 'Tentar novamente' : 'Retry',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChips extends StatelessWidget {
  const _TimeChips({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final s = ctrl.isPt;
    final chips = [
      (TimePeriod.now,     s ? 'Agora'         : 'Now'),
      (TimePeriod.tonight, s ? 'Esta noite'    : 'Tonight'),
      (TimePeriod.weekend, s ? 'Fim de semana' : 'Weekend'),
    ];

    return Row(
      children: chips.map((c) {
        final active = ctrl.timePeriod == c.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => ctrl.setTimePeriod(c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.teal
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: active
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                c.$2,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active
                      ? const Color(0xFF0a0f1e)
                      : Colors.white60,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NeighborhoodGrid extends StatelessWidget {
  const _NeighborhoodGrid({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final items = ctrl.filteredAreas;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            ctrl.isPt
                ? 'Nenhum bairro encontrado.'
                : 'No neighborhoods found.',
            style:
                GoogleFonts.dmSans(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final name = items[i]['name'] as String;
        final level = ctrl.riskBadges[name];
        return _NeighborhoodCard(
          name: name,
          riskLevel: level,
          isPt: ctrl.isPt,
          onTap: () => ctrl.selectArea(name),
        );
      },
    );
  }
}

class _NeighborhoodCard extends StatelessWidget {
  const _NeighborhoodCard({
    required this.name,
    required this.riskLevel,
    required this.isPt,
    required this.onTap,
  });
  final String name;
  final String? riskLevel;
  final bool isPt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatAreaName(name),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (riskLevel != null)
              _RiskBadge(level: riskLevel!, isPt: isPt)
            else
              Container(
                height: 18,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.level, required this.isPt});
  final String level;
  final bool isPt;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (level) {
      'high'   => (
          const Color(0x26DC3232),
          AppTheme.red,
          isPt ? 'Alto' : 'High',
        ),
      'medium' => (
          const Color(0x26FFA500),
          AppTheme.amber,
          isPt ? 'Médio' : 'Medium',
        ),
      _        => (
          const Color(0x2600E5A0),
          AppTheme.teal,
          isPt ? 'Baixo' : 'Low',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final risk  = ctrl.riskScore;
    final speed = ctrl.avgSpeed;
    final wx    = ctrl.weather;
    final s     = ctrl.isPt;

    final (safetyLabel, safetyColor) = _safetyInfo(risk, s);
    final (trafficLabel, trafficColor) = _trafficInfo(speed, s);
    final (weatherLabel, _) = _weatherInfo(wx);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            emoji: '🛡',
            label: s ? 'Segurança' : 'Safety',
            value: safetyLabel,
            color: safetyColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            emoji: '🚗',
            label: s ? 'Trânsito' : 'Traffic',
            value: trafficLabel,
            color: trafficColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            emoji: '🌤',
            label: s ? 'Clima' : 'Weather',
            value: weatherLabel,
            color: AppTheme.blue,
          ),
        ),
      ],
    );
  }

  (String, Color) _safetyInfo(RiskScoreModel? risk, bool pt) {
    if (risk == null) return ('—', Colors.white38);
    return switch (risk.riskLevel) {
      'high'   => (pt ? 'Alto'     : 'High',     AppTheme.red),
      'medium' => (pt ? 'Moderado' : 'Moderate', AppTheme.amber),
      _        => (pt ? 'Baixo'    : 'Low',       AppTheme.teal),
    };
  }

  (String, Color) _trafficInfo(double? speed, bool pt) {
    if (speed == null) return ('—', Colors.white38);
    if (speed < 20) return (pt ? 'Parado'  : 'Stopped', AppTheme.red);
    if (speed < 40) return (pt ? 'Lento'   : 'Slow',    AppTheme.amber);
    return (pt ? 'Fluindo' : 'Flowing', AppTheme.teal);
  }

  (String, Color) _weatherInfo(WeatherCurrent? wx) {
    if (wx == null) return ('—', Colors.white38);
    if (wx.precipitation > 2)
      return ('🌧 ${wx.temperature.round()}°C', AppTheme.blue);
    if (wx.precipitation > 0)
      return ('🌦 ${wx.temperature.round()}°C', AppTheme.blue);
    return ('☀️ ${wx.temperature.round()}°C', AppTheme.blue);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });
  final String emoji;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            label,
            style:
                GoogleFonts.dmSans(fontSize: 10, color: Colors.white38),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBlock extends StatelessWidget {
  const _GuideBlock({required this.ctrl, required this.pulseAnim});
  final HomeController ctrl;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    final s = ctrl.isPt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.teal
                      .withOpacity(0.5 + 0.5 * pulseAnim.value),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.teal
                          .withOpacity(0.4 * pulseAnim.value),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s ? 'Guia local' : 'Local guide',
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ctrl.isLoadingAI
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: AppTheme.teal, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      s
                          ? 'Consultando guia local...'
                          : 'Consulting local guide...',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: Colors.white54),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: AppTheme.teal, width: 2),
                  ),
                ),
                child: Text(
                  ctrl.aiResponse ??
                      (s
                          ? 'Sem informações disponíveis.'
                          : 'No information available.'),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.6,
                  ),
                ),
              ),
      ],
    );
  }
}
