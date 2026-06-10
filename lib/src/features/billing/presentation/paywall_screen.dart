// SPEC-198 — pantalla de paywall.
//
// Muestra los packages de la Offering activa con PRECIO LOCALIZADO del SDK
// (nunca hardcodeado), botón de compra por package, y "Restaurar compras"
// (obligatorio App Store). Maneja compra ok / cancelada / error sin romper.
// Telemetría de conversión (SPEC-193). Usa la capa BillingService (agnóstica);
// los tests la inyectan con FakeBillingService.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.trigger = 'manual'});

  /// De dónde se abrió (lock, coaching, día7, ayuno…) — para telemetría.
  final String trigger;

  /// Abre el paywall como hoja modal scrollable.
  static Future<void> show(BuildContext context, {String trigger = 'manual'}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaywallScreen(trigger: trigger),
    );
  }

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<BillingPackage> _packages = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent(
      AnalyticsEvents.paywallShown,
      params: {AnalyticsParams.feature: widget.trigger},
    );
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final pkgs = await ref.read(billingServiceProvider).currentOfferingPackages();
    if (!mounted) return;
    setState(() {
      _packages = pkgs;
      _loading = false;
    });
  }

  Future<void> _buy(BillingPackage pkg) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref.read(billingServiceProvider).purchase(pkg);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result.outcome) {
      case PurchaseOutcome.success:
        final isTrial = result.status?.source == EntitlementSource.trial;
        if (isTrial) {
          AnalyticsService.logEvent(AnalyticsEvents.trialStarted,
              params: {AnalyticsParams.plan: pkg.productId});
        }
        AnalyticsService.logEvent(
          AnalyticsEvents.purchaseCompleted,
          params: {
            AnalyticsParams.plan: pkg.productId,
            AnalyticsParams.trigger: widget.trigger,
          },
        );
        Navigator.of(context).maybePop();
      case PurchaseOutcome.cancelled:
        break; // sin ruido
      case PurchaseOutcome.error:
        AnalyticsService.logEvent(AnalyticsEvents.purchaseFailed,
            params: {AnalyticsParams.plan: pkg.productId});
        _snack(result.errorMessage ?? 'No se pudo completar la compra.');
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref.read(billingServiceProvider).restore();
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.isSuccess && (result.status?.isPremium ?? false)) {
      AnalyticsService.logEvent(AnalyticsEvents.purchaseRestored);
      Navigator.of(context).pop();
    } else {
      _snack('No encontramos compras para restaurar.');
    }
  }

  void _close() {
    AnalyticsService.logEvent(
      AnalyticsEvents.paywallDismissed,
      params: {AnalyticsParams.feature: widget.trigger},
    );
    Navigator.of(context).pop();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _close,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Text(
              'Elena Premium',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Coaching ilimitado, tu tendencia completa y sincronización '
              'automática. 14 días gratis.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_packages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Los planes no están disponibles ahora mismo.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ..._packages.map(_buildPackageTile),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _restore,
              child: const Text('Restaurar compras'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageTile(BillingPackage pkg) {
    final theme = Theme.of(context);
    final periodLabel = switch (pkg.period) {
      BillingPeriod.monthly => 'Mensual',
      BillingPeriod.annual => 'Anual',
      BillingPeriod.unknown => pkg.title,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton(
        onPressed: _busy ? null : () => _buy(pkg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(periodLabel,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(pkg.priceString, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
