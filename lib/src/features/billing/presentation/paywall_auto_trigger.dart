// SPEC-198 §2.2/§2.4 — orquestador invisible montado en el Home.
//
// Una vez por sesión, post-frame:
//   - programa/cancela los nudges día 5/12 según premium,
//   - si corresponde (PaywallTrigger), ofrece el paywall proactivo y lo marca
//     como mostrado hoy (no satura).
// No dibuja nada (SizedBox.shrink). Lee estado ya cargado por otros providers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/application/paywall_nudges.dart';
import 'package:elena_app/src/features/billing/application/paywall_prompt_store.dart';
import 'package:elena_app/src/features/billing/application/paywall_trigger.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_screen.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_history_provider.dart';

class PaywallAutoTrigger extends ConsumerStatefulWidget {
  const PaywallAutoTrigger({super.key});

  @override
  ConsumerState<PaywallAutoTrigger> createState() => _PaywallAutoTriggerState();
}

class _PaywallAutoTriggerState extends ConsumerState<PaywallAutoTrigger> {
  bool _ran = false;

  @override
  Widget build(BuildContext context) {
    if (!_ran) {
      _ran = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _evaluate();
      });
    }
    return const SizedBox.shrink();
  }

  Future<void> _evaluate() async {
    final isPremium = ref.read(isPremiumProvider);
    final account = ref.read(authStateProvider).valueOrNull;
    final createdAt = account?.createdAt;

    // Nudges: programar si Free + hay fecha de registro; cancelar si Premium.
    if (isPremium) {
      await PaywallNudges.cancel();
    } else if (createdAt != null) {
      await PaywallNudges.schedule(createdAt);
    }

    if (isPremium) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final onboardingCompleted =
        prefs.getBool('onboardingCompleted') ?? false;
    final now = DateTime.now();
    final days = createdAt == null ? 0 : now.difference(createdAt).inDays;
    final fastsCompleted =
        ref.read(hasCompletedFastingTodayProvider) ? 1 : 0;
    final store = ref.read(paywallPromptStoreProvider);

    final shouldOffer = PaywallTrigger.shouldOffer(
      isPremium: isPremium,
      onboardingCompleted: onboardingCompleted,
      daysSinceRegistration: days,
      fastsCompleted: fastsCompleted,
      shownToday: store.shownToday(now),
    );
    if (!shouldOffer || !mounted) return;

    await store.markShown(now);
    if (!mounted) return;
    await PaywallScreen.show(context, trigger: 'auto');
  }
}
