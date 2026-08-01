// SPEC-261.9: historial de salidas (seguimiento en el tiempo).
//
// Reconstruye las salidas desde alcohol_history y muestra un resumen, una
// tendencia simple (barras de las últimas salidas) y la lista. Sin moralizar:
// informa para que el usuario vea su patrón.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/alcohol/application/outing_history_provider.dart';
import 'package:elena_app/src/features/alcohol/domain/outing_history.dart';

const Color _accent = Color(0xFFB4654A);
const Color _card = Color(0xFF1E293B);

class AlcoholHistoryScreen extends ConsumerWidget {
  const AlcoholHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(outingHistoryProvider);
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
        title: const Text('Tus salidas',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: async.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _accent)),
          error: (_, __) => _centered(
              'No pudimos cargar tu historial. Prueba de nuevo más tarde.'),
          data: (outings) =>
              outings.isEmpty ? _empty() : _Content(outings: outings),
        ),
      ),
    );
  }

  Widget _empty() => _centered(
        'Todavía no registraste ninguna salida.\n'
        'Cuando uses el Modo Fiesta, tus noches aparecerán acá.',
      );

  Widget _centered(String text) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5),
          ),
        ),
      );
}

class _Content extends StatelessWidget {
  const _Content({required this.outings});
  final List<Outing> outings;

  @override
  Widget build(BuildContext context) {
    final s = OutingHistory.summary(outings, now: DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _SummaryCard(outingsCount: s.outings, totalUnits: s.totalUnits),
        const SizedBox(height: 20),
        if (outings.length >= 2) ...[
          _sectionLabel('TENDENCIA (UEA POR SALIDA)'),
          const SizedBox(height: 10),
          _TrendBars(outings: outings),
          const SizedBox(height: 24),
        ],
        _sectionLabel('SALIDAS'),
        const SizedBox(height: 8),
        ...outings.map((o) => _OutingRow(outing: o)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.outingsCount, required this.totalUnits});
  final int outingsCount;
  final double totalUnits;

  @override
  Widget build(BuildContext context) {
    final avg = outingsCount == 0 ? 0.0 : totalUnits / outingsCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimos 30 días',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat('$outingsCount', outingsCount == 1 ? 'salida' : 'salidas'),
              _divider(),
              _stat(totalUnits.toStringAsFixed(1), 'UEA en total'),
              _divider(),
              _stat(avg.toStringAsFixed(1), 'UEA por salida'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withValues(alpha: 0.08),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.outings});
  final List<Outing> outings;

  @override
  Widget build(BuildContext context) {
    // Últimas 8 salidas, de la más vieja (izq) a la más nueva (der).
    final shown = outings.take(8).toList().reversed.toList();
    final maxUnits = shown
        .map((o) => o.totalStandardUnits)
        .fold<double>(1.0, (m, u) => u > m ? u : m);
    const maxBarHeight = 90.0;

    return SizedBox(
      height: maxBarHeight + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: shown.map((o) {
          final h = (o.totalStandardUnits / maxUnits) * maxBarHeight;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(o.totalStandardUnits.toStringAsFixed(0),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10)),
                  const SizedBox(height: 4),
                  Container(
                    height: h < 6 ? 6 : h,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${o.night.day}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OutingRow extends StatelessWidget {
  const _OutingRow({required this.outing});
  final Outing outing;

  static const _wd = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _mo = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
  ];

  String get _dateLabel {
    final n = outing.night;
    return '${_wd[n.weekday - 1]} ${n.day} ${_mo[n.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${outing.drinkCount} ${outing.drinkCount == 1 ? "trago" : "tragos"} · '
                  '${outing.totalStandardUnits.toStringAsFixed(1)} UEA',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(outing.intensityLabel,
                style: const TextStyle(
                    color: _accent, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(String text) => Text(
      text,
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5),
    );
