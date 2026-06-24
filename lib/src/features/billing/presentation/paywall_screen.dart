// SPEC-198 — pantalla de paywall. Rediseño pro (2026-06-24).
//
// Patrón trial-first: el precio queda en segundo plano; el CTA principal
// es "Comenzar 14 días gratis". El usuario selecciona un plan (anual
// preseleccionado por mayor valor y mejor conversión) y ve el precio
// DESPUÉS del botón — nunca dentro de él. Mismo patrón que Headspace,
// Calm y Duolingo.
//
// Lógica de negocio intacta: telemetría SPEC-193, purchase / restore /
// cancel / error, FakeBillingService compatible.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

// ── Beneficios mostrados en el header ────────────────────────────────────────

const List<_Feature> _kFeatures = [
  _Feature(
    icon: Icons.psychology_rounded,
    text: 'Coaching ilimitado todos los días',
  ),
  _Feature(
    icon: Icons.show_chart_rounded,
    text: 'Historial completo de tu IMR semana a semana',
  ),
  _Feature(
    icon: Icons.watch_rounded,
    text: 'Sincronización automática con Apple Health',
  ),
  _Feature(
    icon: Icons.loop_rounded,
    text: 'Retroalimentación detallada de cada ciclo metabólico',
  ),
];

// ── Widget principal ──────────────────────────────────────────────────────────

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
      useSafeArea: true,
      builder: (_) => PaywallScreen(trigger: trigger),
    );
  }

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with SingleTickerProviderStateMixin {
  List<BillingPackage> _packages = const [];
  bool _loading = true;
  bool _busy = false;

  /// Índice del plan seleccionado actualmente.
  /// Arranca en 1 (anual) para maximizar conversión — el anual tiene
  /// mayor valor percibido y mejor precio por mes.
  int _selectedIndex = 1;

  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    AnalyticsService.logEvent(
      AnalyticsEvents.paywallShown,
      params: {AnalyticsParams.feature: widget.trigger},
    );
    _loadPackages();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    final pkgs =
        await ref.read(billingServiceProvider).currentOfferingPackages();
    if (!mounted) return;
    setState(() {
      _packages = pkgs;
      _loading = false;
      // Si solo hay un plan, seleccionarlo.
      if (_packages.length == 1) _selectedIndex = 0;
      // Si el índice preseleccionado supera los paquetes disponibles, ajustar.
      if (_selectedIndex >= _packages.length) {
        _selectedIndex = _packages.length - 1;
      }
    });
  }

  Future<void> _buySelected() async {
    if (_busy || _packages.isEmpty) return;
    final pkg = _packages[_selectedIndex];
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
        if (!mounted) return;
        Navigator.of(context).maybePop();
      case PurchaseOutcome.cancelled:
        break;
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
      _snack('No encontramos compras previas para restaurar.');
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

  /// Línea de precio + disclaimer bajo el botón CTA.
  /// Ejemplo: "Después US$4.99/mes · Sin cargo hoy · Cancela cuando quieras"
  String _disclaimerText() {
    if (_packages.isEmpty) return '';
    final pkg = _packages[_selectedIndex];
    final period = pkg.period == BillingPeriod.annual ? 'año' : 'mes';
    return 'Después ${pkg.priceString} · Sin cargo hoy · Cancela cuando quieras';
  }

  /// Porcentaje de ahorro del plan anual respecto al mensual (si ambos existen).
  String? _annualSavings() {
    if (_packages.length < 2) return null;
    try {
      final monthly = _packages.firstWhere(
          (p) => p.period == BillingPeriod.monthly);
      final annual = _packages.firstWhere(
          (p) => p.period == BillingPeriod.annual);

      // Extraer número del priceString (ej. "US$4.99/mes" → 4.99).
      double _parsePrice(String s) {
        final match = RegExp(r'[\d,]+\.?\d*').firstMatch(s);
        if (match == null) return 0;
        return double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 0;
      }

      final mPrice = _parsePrice(monthly.priceString);
      final aPrice = _parsePrice(annual.priceString);
      if (mPrice <= 0 || aPrice <= 0) return null;
      final saving = ((mPrice * 12 - aPrice) / (mPrice * 12) * 100).round();
      if (saving <= 0) return null;
      return 'AHORRA $saving%';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final savings = _annualSavings();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.metabolicGreen.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Botón cerrar ───────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _close,
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),

              // ── Header: ícono + título ─────────────────────────────────
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.metabolicGreen.withValues(alpha: 0.30),
                        AppColors.metabolicGreen.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.metabolicGreen.withValues(alpha: 0.40),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.metabolicGreen,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Elena Premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prueba gratis 14 días — sin cargo hasta que decidas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.metabolicGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // ── Beneficios ─────────────────────────────────────────────
              ..._kFeatures.map(_buildFeatureRow),

              const SizedBox(height: 24),

              // ── Divisor sutil ──────────────────────────────────────────
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.07),
              ),
              const SizedBox(height: 20),

              // ── Selector de plan ───────────────────────────────────────
              Text(
                'ELIGE TU PLAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 10),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.metabolicGreen,
                    ),
                  ),
                )
              else if (_packages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Los planes no están disponibles en este momento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                )
              else
                _buildPlanSelector(savings),

              const SizedBox(height: 20),

              // ── CTA principal ──────────────────────────────────────────
              _buildCTA(),

              const SizedBox(height: 10),

              // ── Disclaimer de precio ───────────────────────────────────
              Text(
                _disclaimerText(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.38),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // ── Restaurar ──────────────────────────────────────────────
              TextButton(
                onPressed: _busy ? null : _restore,
                child: Text(
                  'Restaurar compras',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Fila de beneficio ──────────────────────────────────────────────────────

  Widget _buildFeatureRow(_Feature f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.metabolicGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              f.icon,
              size: 15,
              color: AppColors.metabolicGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                f.text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de plan (cards seleccionables) ────────────────────────────────

  Widget _buildPlanSelector(String? savings) {
    return Row(
      children: List.generate(_packages.length, (i) {
        final pkg = _packages[i];
        final isSelected = i == _selectedIndex;
        final isAnnual = pkg.period == BillingPeriod.annual;
        final label = isAnnual ? 'Anual' : 'Mensual';

        // Precio por mes derivado del priceString para la comparación visual.
        String? perMonth;
        if (isAnnual && _packages.length > 1) {
          try {
            final match =
                RegExp(r'[\d,]+\.?\d*').firstMatch(pkg.priceString);
            if (match != null) {
              final total =
                  double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 0;
              final pm = total / 12;
              perMonth = '\$${pm.toStringAsFixed(2)}/mes';
            }
          } catch (_) {}
        }

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < _packages.length - 1 ? 10 : 0),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.metabolicGreen.withValues(alpha: 0.12)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.metabolicGreen
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge "AHORRA X%" solo en plan anual
                  if (isAnnual && savings != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.metabolicGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        savings,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pkg.priceString,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.metabolicGreen
                          : Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
                  if (perMonth != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      perMonth,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Radio indicator
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.metabolicGreen
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.metabolicGreen
                              : Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              size: 12, color: Colors.black)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Botón CTA ──────────────────────────────────────────────────────────────

  Widget _buildCTA() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _busy
          ? Container(
              key: const ValueKey('loading'),
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.metabolicGreen.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            )
          : GestureDetector(
              key: const ValueKey('cta'),
              onTap: _packages.isEmpty ? null : _buySelected,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: _packages.isEmpty
                      ? null
                      : const LinearGradient(
                          colors: [
                            Color(0xFF10B981),
                            Color(0xFF059669),
                          ],
                        ),
                  color:
                      _packages.isEmpty ? const Color(0xFF1E293B) : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _packages.isEmpty
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.metabolicGreen
                                .withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    'Comenzar 14 días gratis',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _packages.isEmpty
                          ? Colors.white38
                          : Colors.black,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Datos de beneficio ────────────────────────────────────────────────────────

class _Feature {
  final IconData icon;
  final String text;

  const _Feature({required this.icon, required this.text});
}
