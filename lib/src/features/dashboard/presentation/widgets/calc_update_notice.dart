// SPEC-306: aviso único a usuarios existentes de que el cálculo de % de
// grasa y edad metabólica cambió para coincidir con la calculadora de
// metamorfosisvital.com.co.
//
// Lo activa el script `functions/scripts/spec306_recalcular_grasa.js`,
// que escribe `users/{uid}.calcUpdateNotice = {pending: true, needsHip}`.
// Al cerrarlo se marca `pending: false`. Los usuarios nuevos no lo ven.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/progress/presentation/biometric_checkin_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalcUpdateNoticeData {
  const CalcUpdateNoticeData({required this.needsHip});
  final bool needsHip;
}

final calcUpdateNoticeProvider =
    StreamProvider.autoDispose<CalcUpdateNoticeData?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  try {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map<CalcUpdateNoticeData?>((snap) {
      final raw = snap.data()?['calcUpdateNotice'];
      if (raw is! Map || raw['pending'] != true) return null;
      return CalcUpdateNoticeData(needsHip: raw['needsHip'] == true);
    }).handleError((Object _) {});
  } catch (_) {
    // Sin Firebase inicializado (tests de widgets): no hay aviso.
    return Stream.value(null);
  }
});

class CalcUpdateNoticeCard extends ConsumerWidget {
  const CalcUpdateNoticeCard({super.key});

  Future<void> _dismiss(WidgetRef ref) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    // Offline-first: no se espera el ack del servidor.
    unawaited(FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'calcUpdateNotice.pending': false}).catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(calcUpdateNoticeProvider).valueOrNull;
    if (data == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Actualizamos el cálculo de tu composición corporal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => _dismiss(ref),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              data.needsHip
                  ? 'Tu % de grasa y tu edad metabólica ahora usan la misma '
                      'fórmula que la calculadora de metamorfosisvital.com.co. '
                      'Para calcularlos necesitamos la medida de tu cadera.'
                  : 'Tu % de grasa y tu edad metabólica ahora usan la misma '
                      'fórmula que la calculadora de metamorfosisvital.com.co. '
                      'Por eso tus cifras pueden haber cambiado un poco.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          if (data.needsHip) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                showBiometricCheckInSheet(context);
                _dismiss(ref);
              },
              child: const Text('Agregar mi cadera',
                  style: TextStyle(fontSize: 15)),
            ),
          ],
        ],
      ),
    );
  }
}
