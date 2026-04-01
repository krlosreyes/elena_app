import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import '../core/widgets/blueprint_grid.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      // Always go to the root location for the 'Hoy' tab (index 0).
      // For other tabs, only go to the root if it's already the current tab.
      initialLocation: index == 0 || index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlueprintGrid(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: _TechnicalBottomAppBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTap(context, index),
        ),
      ),
    );
  }
}

class _TechnicalBottomAppBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TechnicalBottomAppBar(
      {required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: AppTheme.outline, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(
            icon: Icons.today_outlined,
            activeIcon: Icons.today_rounded,
            label: 'HOY',
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavIcon(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            label: 'PROGRESO',
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavIcon(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'PERFIL',
            active: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(active ? activeIcon : icon,
              color: active ? AppTheme.primary : AppTheme.textDim, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? AppTheme.primary : AppTheme.textDim,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
