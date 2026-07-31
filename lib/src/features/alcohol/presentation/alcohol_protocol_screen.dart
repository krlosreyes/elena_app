// SPEC-261: pantalla del Protocolo de Consumo Consciente.
//
// Reducción de daño, sin moralizar. Acompaña en cuatro fases (Antes /
// Durante / Después / Recuperación). Todo el estado vive en
// `consumptionProvider`; esta pantalla solo lo dibuja y dispara acciones.
//
// El reloj de metabolización usa un peso de referencia (70 kg) en esta
// primera versión; personalizarlo con el peso real del usuario es un ajuste
// menor cuando se conecte el perfil.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/alcohol/application/consumption_notifier.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_impact.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_math.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';

class AlcoholProtocolScreen extends ConsumerWidget {
  const AlcoholProtocolScreen({super.key});

  static const _accent = Color(0xFFB4654A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(consumptionProvider);
    final notifier = ref.read(consumptionProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Consumo consciente',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          if (session.isActive)
            TextButton(
              onPressed: notifier.endProtocol,
              child: Text('Cerrar',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SafeArea(
        child: session.isActive
            ? _ActiveBody(session: session, notifier: notifier, accent: _accent)
            : _IntroBody(notifier: notifier, accent: _accent),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Intro (protocolo inactivo)
// ─────────────────────────────────────────────────────────────────────
class _IntroBody extends StatelessWidget {
  const _IntroBody({required this.notifier, required this.accent});
  final ConsumptionNotifier notifier;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.wine_bar, color: accent, size: 30),
              const SizedBox(height: 12),
              const Text(
                'Vas a compartir unos tragos',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Sin sermones. Activamos un plan simple para que el impacto '
                'metabólico sea el mínimo posible y la recuperación, la máxima.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _phaseTile(
            '1 · Antes', 'Hidratarte, comer algo y fijar tu meta de la noche.'),
        _phaseTile('2 · Durante', 'Registrar cada trago, agua 1:1 y espaciar.'),
        _phaseTile('3 · Después', 'Agua + electrolitos y cuidar el sueño.'),
        _phaseTile('4 · Recuperación',
            'Ayuno de recuperación e hidratación al día siguiente.'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => notifier.startProtocol(),
            child: const Text('Activar protocolo',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Esto no es consejo médico. La estimación de alcoholemia es '
          'orientativa y nunca debe usarse para decidir si conducir.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              height: 1.4),
        ),
      ],
    );
  }

  Widget _phaseTile(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(body,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Cuerpo activo
// ─────────────────────────────────────────────────────────────────────
class _ActiveBody extends StatelessWidget {
  const _ActiveBody({
    required this.session,
    required this.notifier,
    required this.accent,
  });
  final ConsumptionSession session;
  final ConsumptionNotifier notifier;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final grams = session.totalGrams;
    final clearH = AlcoholMath.hoursToMetabolize(grams: grams, weightKg: 70);
    final netCost = AlcoholImpact.netCostForSession(session);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _summaryCard(grams, session, clearH, netCost),
        const SizedBox(height: 20),
        _mitigationSection(),
        const SizedBox(height: 20),
        _drinksSection(),
        const SizedBox(height: 20),
        _catalogSection(),
      ],
    );
  }

  Widget _summaryCard(
      double grams, ConsumptionSession s, double clearH, double netCost) {
    final unidades = s.totalStandardUnits;
    final over = s.budgetExceeded;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric('${unidades.toStringAsFixed(1)} UEA',
                  'de ${s.budgetStandardUnits.toStringAsFixed(1)}',
                  color: over ? const Color(0xFFE879A6) : Colors.white),
              _metric('${grams.toStringAsFixed(0)} g', 'alcohol'),
              _metric(AlcoholMath.formatHours(clearH), 'para volver a cero'),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
          Text(
            'Impacto estimado: ${AlcoholImpact.label(netCost)} '
            '(${netCost.toStringAsFixed(0)} pts)',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            over
                ? 'Vas por encima de tu meta. Sin juzgar: un vaso de agua y bajá el ritmo.'
                : 'Vas dentro del plan. Un vaso de agua por trago te mantiene ahí.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }

  Widget _mitigationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('REDUCCIÓN DE DAÑO'),
        _switchTile('Me hidraté antes (agua + electrolitos)',
            session.hydratedBefore, notifier.setHydratedBefore),
        _switchTile('Comí proteína/grasa/fibra antes', session.ateBefore,
            notifier.setAteBefore),
        _switchTile('Plan de ayuno de recuperación mañana',
            session.recoveryFastPlanned, notifier.setRecoveryFastPlanned),
      ],
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _drinksSection() {
    if (session.drinks.isEmpty) {
      return _sectionLabel('AÚN SIN TRAGOS REGISTRADOS');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('LO QUE LLEVAS'),
            TextButton.icon(
              onPressed: notifier.removeLastDrink,
              icon: Icon(Icons.undo_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.6)),
              label: Text('Deshacer',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12)),
            ),
          ],
        ),
        ...session.drinks.reversed.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 7, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(d.name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  Text('${d.grams.toStringAsFixed(0)} g',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _catalogSection() {
    final categories = DrinkCategory.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('REGISTRAR UN TRAGO'),
        for (final cat in categories) ..._categoryBlock(cat),
      ],
    );
  }

  List<Widget> _categoryBlock(DrinkCategory cat) {
    final items = AlcoholCatalog.byCategory(cat);
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(_categoryLabel(cat),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((item) => _DrinkChip(
                  item: item,
                  accent: accent,
                  onTap: () => notifier.logDrink(item),
                ))
            .toList(),
      ),
    ];
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );

  static String _categoryLabel(DrinkCategory c) => switch (c) {
        DrinkCategory.cerveza => 'Cervezas',
        DrinkCategory.vino => 'Vinos',
        DrinkCategory.espumanteFortificado => 'Espumantes y fortificados',
        DrinkCategory.destilado => 'Destilados',
        DrinkCategory.aguardienteLatam => 'Aguardientes',
        DrinkCategory.coctel => 'Cócteles',
        DrinkCategory.sinAlcohol => 'Sin / bajo alcohol',
      };
}

class _DrinkChip extends StatelessWidget {
  const _DrinkChip({
    required this.item,
    required this.accent,
    required this.onTap,
  });
  final AlcoholCatalogItem item;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(item.name,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 6),
            Text('${item.standardUnitsFor().toStringAsFixed(1)} UEA',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
