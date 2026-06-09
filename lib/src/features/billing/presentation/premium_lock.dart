// SPEC-197 — envoltorio de contenido premium.
//
// Si `isLocked` es false (premium) muestra el hijo tal cual. Si está locked
// (Free), muestra el hijo atenuado con un candado + CTA "Desbloquear" que
// llama `onUpgrade` (SPEC-198 lo conectará al paywall). NO contiene lógica de
// cobro; recibe el estado por parámetro para ser testeable sin providers.
//
// Un helper `PremiumLock.gated` lee `featureGateProvider` para el uso normal.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/billing/application/billing_providers.dart';

class PremiumLock extends StatelessWidget {
  const PremiumLock({
    super.key,
    required this.isLocked,
    required this.child,
    required this.onUpgrade,
    this.label = 'Función Premium',
  });

  /// Helper que decide el lock desde `featureGateProvider`. `allowed` extrae
  /// el booleano del gate (p. ej. `(g) => g.analyticsHistoryAllowed`).
  static Widget gated({
    Key? key,
    required bool Function(WidgetRef ref) allowed,
    required Widget child,
    required VoidCallback onUpgrade,
    String label = 'Función Premium',
  }) {
    return Consumer(
      builder: (context, ref, _) => PremiumLock(
        key: key,
        isLocked: !allowed(ref),
        onUpgrade: onUpgrade,
        label: label,
        child: child,
      ),
    );
  }

  final bool isLocked;
  final Widget child;
  final VoidCallback onUpgrade;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    final theme = Theme.of(context);
    return Stack(
      children: [
        // Contenido atenuado y no interactivo (preview del valor).
        IgnorePointer(
          child: Opacity(opacity: 0.35, child: child),
        ),
        Positioned.fill(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: theme.colorScheme.primary, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: onUpgrade,
                  child: const Text('Desbloquear'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
