import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.navy,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.teal,
                  child: const Text(
                    'RI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Roberto Ikkoh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Los Angeles, CA',
                  style: TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
              ],
            ),
          ),

          const _SectionLabel('Navegação'),
          _NavItem(icon: Icons.map,              label: 'Mapa interativo',  route: '/',           currentRoute: currentRoute),
          _NavItem(icon: Icons.bar_chart,         label: 'Dashboard',        route: '/dashboard',  currentRoute: currentRoute),
          _NavItem(icon: Icons.smart_toy_outlined,label: 'Assistente',       route: '/assistant',  currentRoute: currentRoute),

          const Divider(color: AppTheme.card, thickness: 1),
          const _SectionLabel('Análise'),
          _NavItem(icon: Icons.access_time,    label: 'Horários de risco',  route: '/analysis/risk-times',    currentRoute: currentRoute),
          _NavItem(icon: Icons.cloud_outlined, label: 'Previsão de risco',  route: '/analysis/risk-forecast', currentRoute: currentRoute),
          _NavItem(icon: Icons.layers,         label: 'Score de risco',     route: '/analysis/risk-score',    currentRoute: currentRoute),

          const Divider(color: AppTheme.card, thickness: 1),
          const _SectionLabel('App'),
          const _StaticItem(icon: Icons.info_outline, label: 'Sobre o projeto'),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.teal : AppTheme.muted,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? AppTheme.teal : AppTheme.muted,
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? AppTheme.teal.withValues(alpha: 0.1) : null,
      dense: true,
      onTap: () {
        Navigator.pop(context);
        if (currentRoute != route) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

class _StaticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StaticItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.muted, size: 20),
      title: Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
      dense: true,
      onTap: () {},
    );
  }
}
