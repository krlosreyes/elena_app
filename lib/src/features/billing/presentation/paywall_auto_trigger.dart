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
import 'package:elena_app/src/features/fasting/application/fasting_history_provider.dart';
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';

class PaywallAutoTrigger extends ConsumerStatefulWidget {
  const PaywallAutoTrigger({super.key});

  @override
  ConsumerState<PaywallAutoTrigger> createState() => _PaywallAutoTriggerState();
}

class _PaywallAutoTriggerState extends ConsumerState<PaywallAutoTrigger> {
  @override
  void initState() {
    super.initState();
    // SPEC-241 Bug 500-501: evaluación inicial post-frame.
    // Antes se usaba un flag `_ran = true` one-shot. Problema: si isPremium
    // venía de caché como `true` en el primer frame y luego cambiaba a `false`,
    // los nudges nunca se reprogramaban. Ahora: evaluamos en initState Y
    // escuchamos cambios en isPremiumProvider via ref.listen en build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _evaluate();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-evaluar si el estado premium cambia (ej: caché frío → Firestore).
    ref.listen(isPremiumProvider, (_, __) {
      if (mounted) _evaluate();
    });
    // SPEC-243 fix: re-evaluar cuando el tour termina, por si el paywall
    // fue bloqueado durante el tour y aún aplica mostrarlo.
    ref.listen(appTourProvider, (prev, next) {
      if (prev?.isActive == true && !next.isActive) {
        if (mounted) _evaluate();
      }
    });
    return const SizedBox.shrink();
  }

  Future<void> _evaluate() async {
    // SPEC-243 fix: el tour tiene prioridad sobre el paywall proactivo.
    // Si el tour está corriendo, diferimos la evaluación — el listener
    // appTourProvider de arriba la re-disparará cuando el tour finalice.
    if (ref.read(appTourProvider).isActive) return;

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
    // GAP-1 fix: usuarios MR migrados saltan el onboarding in-app y nunca
    // setean la clave 'onboardingCompleted'. Tratamos account.isComplete
    // como equivalente — si el perfil está completo en Firestore, el usuario
    // ya completó el flujo de registro y tiene valor demostrado suficiente.
    final onboardingCompleted =
        (prefs.getBool('onboardingCompleted') ?? false) ||
            (account?.isComplete == true);
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
