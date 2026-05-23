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

  AppPhase? _prevPhase;
  String?   _prevArea;

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
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
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
                        fontFamily: 'Syne', fontSize: 15,
                        fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Analytics',
                      style: TextStyle(
                        fontFamily: 'Syne', fontSize: 15,
                        fontWeight: FontWeight.w700, color: AppTheme.teal,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'System · Los Angeles',
                style: GoogleFonts.dmSans(
                    fontSize: 9, color: Colors.white.withOpacity(0.3)),
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
                    color: Colors.white70),
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
              // Item 3 — zoom livre (scroll + pinch + drag)
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.urban.analytics',
              ),
              if (ctrl.heatmapPoints.isNotEmpty)
                Builder(builder: (ctx) {
                  final zoom = MapCamera.of(ctx).zoom;
                  final radius = (zoom * 2.8).clamp(10.0, 120.0);
                  return HeatMapLayer(
                    heatMapDataSource:
                        InMemoryHeatMapDataSource(data: ctrl.heatmapPoints),
                    heatMapOptions: HeatMapOptions(
                      gradient: HeatMapOptions.defaultGradient,
                      minOpacity: 0.3,
                      radius: radius,
                    ),
                  );
                }),
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
                  colors: [
                    AppTheme.navy.withOpacity(0),
                    AppTheme.navy,
                  ],
                ),
              ),
            ),
          ),
          // Badge de localização
          Positioned(
            bottom: 12, left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.navy.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, __) => Container(
                      width: 6, height: 6,
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
            top: 10, right: 10,
            child: _FullscreenButton(onTap: onFullscreen),
          ),
          // Item 4 — Legendas criminalidade + tráfego
          Positioned(
            bottom: 12, right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapLegend(
                  title: ctrl.isPt ? 'CRIMINALIDADE' : 'CRIME',
                  items: const [
                    _LegendItem(color: Color(0xFFFF5555), label: 'Alta'),
                    _LegendItem(color: Color(0xFFFFAA00), label: 'Moderada'),
                    _LegendItem(color: Color(0xFF4CAF50), label: 'Baixa'),
                  ],
                ),
                const SizedBox(height: 6),
                _MapLegend(
                  title: ctrl.isPt ? 'TRÂNSITO' : 'TRAFFIC',
                  items: const [
                    _LegendItem(color: Color(0xFF4FC3F7), label: 'Fluindo'),
                    _LegendItem(color: Color(0xFFFFAA00), label: 'Moderado'),
                    _LegendItem(color: Color(0xFFFF4444), label: 'Lento'),
                  ],
                ),
              ],
            ),
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
            // Item 3 — zoom livre
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.urban.analytics',
            ),
            if (ctrl.heatmapPoints.isNotEmpty)
              Builder(builder: (ctx) {
                final zoom = MapCamera.of(ctx).zoom;
                final radius = (zoom * 2.8).clamp(10.0, 120.0);
                return HeatMapLayer(
                  heatMapDataSource:
                      InMemoryHeatMapDataSource(data: ctrl.heatmapPoints),
                  heatMapOptions: HeatMapOptions(
                    gradient: HeatMapOptions.defaultGradient,
                    minOpacity: 0.3,
                    radius: radius,
                  ),
                );
              }),
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
                colors: [
                  AppTheme.navy.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Botão sair fullscreen
        Positioned(
          top: 12, right: 12,
          child: GestureDetector(
            onTap: onExit,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.navy.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withOpacity(0.15)),
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
                colors: [
                  AppTheme.navy.withOpacity(0.75),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Badge localização
        Positioned(
          bottom: 16, left: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    width: 6, height: 6,
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
          bottom: 16, right: 16,
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
    if (c.isNowMode) {
      return pt
          ? 'Agora · ${c.currentHour}h'
          : 'Now · ${c.currentHour}h';
    }
    return '${c.currentHour}h';
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
    final timeLabel = ctrl.isNowMode
        ? (s
            ? 'Agora · ${ctrl.currentHour}h'
            : 'Now · ${ctrl.currentHour}h')
        : '${ctrl.currentHour}h';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.navy,
        border: Border(
            bottom: BorderSide(color: AppTheme.border, width: 0.5)),
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
            style: GoogleFonts.dmSans(
                fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ESTADO 1 — hero text + seletor + busca + grids de bairros
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
          // Item 1 — "Aonde vamos hoje?"
          _HeroText(isPt: s),
          // Item 5 — Novo seletor de horário
          _NewTimeSelector(ctrl: ctrl),
          const SizedBox(height: 14),
          // Campo de busca
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              controller: searchCtrl,
              onChanged: ctrl.setSearchQuery,
              style:
                  GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: s
                    ? 'Buscar bairro...'
                    : 'Search neighborhood...',
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
          // Grid LAPD
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
          // Item 6 — Grid turístico
          const SizedBox(height: 24),
          Text(
            s ? 'PONTOS TURÍSTICOS' : 'TOURIST SPOTS',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.35),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _TouristGrid(ctrl: ctrl),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ESTADO 2 — cards de risco/trânsito/clima + chat IA
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
          // Item 7 — Chat com IA
          _ChatBlock(ctrl: ctrl, pulseAnim: pulseAnim),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ITEM 1 — HERO TEXT "Aonde vamos hoje?"
// ══════════════════════════════════════════════════════════════════════════════

class _HeroText extends StatelessWidget {
  const _HeroText({required this.isPt});
  final bool isPt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPt ? 'SEU GUIA LOCAL' : 'YOUR LOCAL GUIDE',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppTheme.teal,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: isPt ? 'Aonde vamos ' : 'Where are we ',
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: isPt ? 'hoje?' : 'going?',
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPt
                ? 'Informações em tempo real sobre segurança, trânsito e clima'
                : 'Real-time information on safety, traffic and weather',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ITEM 5 — NOVO SELETOR DE HORÁRIO
// ══════════════════════════════════════════════════════════════════════════════

class _NewTimeSelector extends StatelessWidget {
  const _NewTimeSelector({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final s = ctrl.isPt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha 1: Tipo de dia
        Row(
          children: [
            _Chip(
              label: s ? 'Dia de semana' : 'Weekday',
              active: ctrl.dayType == DayType.weekday,
              onTap: () => ctrl.setDayType(DayType.weekday),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: s ? 'Fim de semana' : 'Weekend',
              active: ctrl.dayType == DayType.weekend,
              onTap: () => ctrl.setDayType(DayType.weekend),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Linha 2: Agora / hora customizada / escolher
        Row(
          children: [
            // Chip "Agora"
            _Chip(
              label: s ? 'Agora' : 'Now',
              active: ctrl.isNowMode,
              onTap: ctrl.setNow,
            ),
            const SizedBox(width: 8),
            // Chip da hora selecionada (visível só quando não é "Agora")
            if (!ctrl.isNowMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.teal.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${ctrl.selectedHour}h',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.teal,
                    ),
                  ),
                ),
              ),
            // Botão "Escolher horário"
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => _HourPickerDialog(
                  initialHour: ctrl.selectedHour,
                  onSelected: ctrl.setHour,
                  isPt: ctrl.isPt,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: Colors.white54),
                    const SizedBox(width: 5),
                    Text(
                      s ? 'Escolher horário' : 'Choose time',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.active,
      required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? AppTheme.navy : Colors.white60,
          ),
        ),
      ),
    );
  }
}

// ── Time Picker Dialog ────────────────────────────────────────────────────────

class _HourPickerDialog extends StatefulWidget {
  const _HourPickerDialog({
    required this.initialHour,
    required this.onSelected,
    required this.isPt,
  });
  final int initialHour;
  final void Function(int) onSelected;
  final bool isPt;

  @override
  State<_HourPickerDialog> createState() => _HourPickerDialogState();
}

class _HourPickerDialogState extends State<_HourPickerDialog> {
  late int _hour;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.isPt;
    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s ? 'Escolher horário' : 'Choose time',
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${_hour.toString().padLeft(2, '0')}h',
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: AppTheme.teal,
              ),
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.teal,
                inactiveTrackColor:
                    Colors.white.withOpacity(0.1),
                thumbColor: AppTheme.teal,
                overlayColor: AppTheme.teal.withOpacity(0.2),
                trackHeight: 3,
              ),
              child: Slider(
                value: _hour.toDouble(),
                min: 0,
                max: 23,
                divisions: 23,
                onChanged: (v) =>
                    setState(() => _hour = v.round()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('00h',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: Colors.white38)),
                Text('23h',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.07),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        s ? 'Cancelar' : 'Cancel',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            color: Colors.white54,
                            fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelected(_hour);
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.teal,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        s ? 'Confirmar' : 'Confirm',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppTheme.navy.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: const Icon(Icons.fullscreen,
            color: Colors.white70, size: 18),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 9),
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

// ══════════════════════════════════════════════════════════════════════════════
// ITEM 2 + 4 — GRID DE BAIRROS (altura fixa 64px + borda selecionado)
// ══════════════════════════════════════════════════════════════════════════════

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
            style: GoogleFonts.dmSans(
                color: Colors.white38, fontSize: 13),
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
        mainAxisExtent: 64, // altura fixa
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final name  = items[i]['name'] as String;
        final level = ctrl.riskBadges[name];
        return _NeighborhoodCard(
          name: name,
          riskLevel: level,
          isPt: ctrl.isPt,
          isSelected: ctrl.selectedArea == name,
          onTap: () => ctrl.selectArea(name),
        );
      },
    );
  }
}

// ── Item 6 — Grid turístico ───────────────────────────────────────────────────

class _TouristGrid extends StatelessWidget {
  const _TouristGrid({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final items = ctrl.touristAreas;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 64,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final name    = items[i]['name'] as String;
        final lapdRef = items[i]['lapd'] as String;
        final level   = ctrl.riskBadges[lapdRef];
        return _NeighborhoodCard(
          name: name,
          riskLevel: level,
          isPt: ctrl.isPt,
          isSelected: ctrl.selectedArea == name,
          onTap: () => ctrl.selectArea(name),
        );
      },
    );
  }
}

// ── Card de bairro (LAPD e turístico) ─────────────────────────────────────────

class _NeighborhoodCard extends StatelessWidget {
  const _NeighborhoodCard({
    required this.name,
    required this.riskLevel,
    required this.isPt,
    required this.isSelected,
    required this.onTap,
  });
  final String  name;
  final String? riskLevel;
  final bool    isPt;
  final bool    isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          // Item 4 — borda teal quando selecionado
          border: Border.all(
            color: isSelected
                ? AppTheme.teal
                : Colors.white.withOpacity(0.07),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                formatAreaName(name),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (riskLevel != null)
              _RiskBadge(level: riskLevel!, isPt: isPt)
            else
              Container(
                height: 18, width: 40,
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
  final bool   isPt;

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
      _ => (
          const Color(0x2600E5A0),
          AppTheme.teal,
          isPt ? 'Baixo' : 'Low',
        ),
    };

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

// ══════════════════════════════════════════════════════════════════════════════
// SUMMARY ROW — 3 cards de resumo (Segurança / Trânsito / Clima)
// ══════════════════════════════════════════════════════════════════════════════

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final risk  = ctrl.riskScore;
    final speed = ctrl.avgSpeed;
    final wx    = ctrl.weather;
    final s     = ctrl.isPt;

    final (safetyLabel, safetyColor)   = _safetyInfo(risk, s);
    final (trafficLabel, trafficColor) = _trafficInfo(speed, s);
    final (weatherLabel, weatherEmoji) = _weatherInfo(ctrl, wx, s);

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
            emoji: weatherEmoji,
            label: s ? 'Clima' : 'Weather',
            value: weatherLabel,
            color: AppTheme.blue,
            isLoading: ctrl.isLoadingGeminiWeather,
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

  /// Usa dados do Gemini quando disponíveis; cai no WeatherCurrent caso contrário.
  (String, String) _weatherInfo(
      HomeController ctrl, WeatherCurrent? wx, bool pt) {
    // Dados em tempo real do Gemini
    if (ctrl.geminiTempC != null && ctrl.geminiCondition != null) {
      final temp = ctrl.geminiTempC!.round();
      final cond = ctrl.geminiCondition!.toLowerCase();
      final emoji = cond.contains('rain') || cond.contains('storm')
          ? '🌧'
          : cond.contains('cloud') || cond.contains('overcast')
              ? '🌥'
              : cond.contains('fog') || cond.contains('mist')
                  ? '🌫'
                  : '☀️';
      // Traduz condição para PT se necessário
      final label = pt ? _translateCondition(ctrl.geminiCondition!) : ctrl.geminiCondition!;
      return ('$emoji ${temp}°C · $label', emoji);
    }
    // Fallback: dataset
    if (wx == null) return ('—', '🌤');
    if (wx.precipitation > 2)
      return ('🌧 ${wx.temperature.round()}°C', '🌧');
    if (wx.precipitation > 0)
      return ('🌦 ${wx.temperature.round()}°C', '🌦');
    return ('☀️ ${wx.temperature.round()}°C', '☀️');
  }

  String _translateCondition(String en) {
    const map = {
      'Sunny': 'Ensolarado',
      'Clear': 'Limpo',
      'Partly Cloudy': 'Parcialmente nublado',
      'Mostly Cloudy': 'Muito nublado',
      'Cloudy': 'Nublado',
      'Overcast': 'Encoberto',
      'Light Rain': 'Chuva leve',
      'Rain': 'Chuva',
      'Heavy Rain': 'Chuva forte',
      'Thunderstorm': 'Tempestade',
      'Fog': 'Neblina',
      'Mist': 'Névoa',
      'Windy': 'Ventoso',
      'Hot': 'Quente',
      'Warm': 'Ameno',
    };
    return map[en] ?? en;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    this.isLoading = false,
  });
  final String emoji;
  final String label;
  final String value;
  final Color  color;
  final bool   isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            style: GoogleFonts.dmSans(
                fontSize: 10, color: Colors.white38),
          ),
          const SizedBox(height: 2),
          if (isLoading)
            SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color.withOpacity(0.6),
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ITEM 7 — CHAT COM IA
// ══════════════════════════════════════════════════════════════════════════════

class _ChatBlock extends StatefulWidget {
  const _ChatBlock({required this.ctrl, required this.pulseAnim});
  final HomeController ctrl;
  final Animation<double> pulseAnim;

  @override
  State<_ChatBlock> createState() => _ChatBlockState();
}

class _ChatBlockState extends State<_ChatBlock> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ChatBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll para o final após novos msgs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients &&
          _scrollCtrl.position.hasContentDimensions) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final t = _inputCtrl.text.trim();
    if (t.isEmpty || widget.ctrl.isChatLoading) return;
    _inputCtrl.clear();
    widget.ctrl.sendChatMessage(t);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.ctrl;
    final s = c.isPt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            AnimatedBuilder(
              animation: widget.pulseAnim,
              builder: (_, __) => Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.teal.withOpacity(
                      0.5 + 0.5 * widget.pulseAnim.value),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.teal.withOpacity(
                          0.4 * widget.pulseAnim.value),
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

        // Loading da resposta inicial
        if (c.isLoadingAI)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                  left: BorderSide(color: AppTheme.teal, width: 2)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.teal),
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
        else ...[
          // Lista de mensagens
          if (c.chatHistory.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: ListView.separated(
                controller: _scrollCtrl,
                shrinkWrap: true,
                itemCount: c.chatHistory.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final msg    = c.chatHistory[i];
                  final isUser = msg['role'] == 'user';
                  return _ChatBubble(
                    text: msg['content'] ?? '',
                    isUser: isUser,
                  );
                },
              ),
            ),

          // Indicador de "respondendo..."
          if (c.isChatLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.teal),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s ? 'Respondendo...' : 'Responding...',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),

          // Campo de input
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.08)),
                  ),
                  child: TextField(
                    controller: _inputCtrl,
                    onSubmitted: (_) => _send(),
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: s
                          ? 'Pergunte sobre o bairro...'
                          : 'Ask about the neighborhood...',
                      hintStyle: GoogleFonts.dmSans(
                          color: Colors.white30, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.teal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.send,
                      color: AppTheme.navy, size: 18),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.isUser});
  final String text;
  final bool   isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: isUser
            ? BoxDecoration(
                color: AppTheme.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.teal.withOpacity(0.3)),
              )
            : BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: const Border(
                    left: BorderSide(
                        color: AppTheme.teal, width: 2)),
              ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: Colors.white
                .withOpacity(isUser ? 0.9 : 0.85),
            height: 1.55,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ITEM 4 — LEGENDAS DO MAPA
// ══════════════════════════════════════════════════════════════════════════════

class _LegendItem {
  const _LegendItem({required this.color, required this.label});
  final Color  color;
  final String label;
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.title, required this.items});
  final String            title;
  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xD90a0f1e), // navy 85%
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: AppTheme.teal,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
