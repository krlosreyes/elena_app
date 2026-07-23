// Módulo "Tu Glucosa" — acciones imperativas sobre
// `GlucoseProtocolState` (propuesta §7.1/§7.4, reglas R2/R10).
//
// No es un StateNotifier: el estado reactivo ya lo expone
// `glucoseProtocolStateProvider` (StreamProvider sobre Firestore) —
// este controller solo agrupa las escrituras (fetch-then-copyWith-then-
// save, mismo patrón documentado en
// exercise/presentation/widgets/rest_day_prompt_sheet.dart) para que
// los widgets no repitan esa lógica ni conozcan el repositorio
// directamente. Mismo criterio de "widget delgado, application layer
// con la lógica" que `buildGlucoseReadingSnapshot`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/glucose/data/glucose_repository_impl.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_consent.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_protocol_state.dart';

class GlucoseProtocolController {
  final Ref _ref;
  const GlucoseProtocolController(this._ref);

  Future<GlucoseProtocolState> _current(String userId) async {
    final repo = _ref.read(glucoseRepositoryProvider);
    return await repo.fetchProtocolState(userId) ??
        GlucoseProtocolState.initial();
  }

  /// R2: acepta el consentimiento vigente. Si es la primera vez, marca
  /// `protocolActive = true` y `activatedAt = now` en el mismo write —
  /// no tiene sentido aceptar el consentimiento sin activar el
  /// protocolo (§7.1: el consentimiento se muestra JUSTO al detectar
  /// elegibilidad o al activar manualmente).
  Future<void> acceptConsent(String userId) async {
    final repo = _ref.read(glucoseRepositoryProvider);
    final existing = await _current(userId);
    final now = DateTime.now();
    await repo.saveProtocolState(
      userId,
      existing.copyWith(
        protocolActive: true,
        activatedAt: existing.activatedAt ?? now,
        paused: false,
        consentAccepted: true,
        consentVersion: kGlucoseConsentVersion,
        consentAcceptedAt: now,
      ),
    );
  }

  /// §5.2 "disponibilidad opcional": activación MANUAL desde Perfil,
  /// para cualquier usuario, independientemente de `pathologies`
  /// (que además es de solo lectura post-onboarding — ver informe de
  /// implementación). Requiere el mismo consentimiento; si ya estaba
  /// aceptado (ej. se había pausado antes), no lo vuelve a pedir.
  Future<void> activateManually(String userId) async {
    final existing = await _current(userId);
    if (existing.consentAccepted &&
        existing.consentVersion >= kGlucoseConsentVersion) {
      final repo = _ref.read(glucoseRepositoryProvider);
      await repo.saveProtocolState(
        userId,
        existing.copyWith(
          protocolActive: true,
          paused: false,
          activatedAt: existing.activatedAt ?? DateTime.now(),
        ),
      );
    } else {
      await acceptConsent(userId);
    }
  }

  /// R10: pausa sin borrar historial ni requerir consentimiento de
  /// nuevo si se reanuda.
  Future<void> pause(String userId) async {
    final repo = _ref.read(glucoseRepositoryProvider);
    final existing = await _current(userId);
    await repo.saveProtocolState(userId, existing.copyWith(paused: true));
  }

  Future<void> resume(String userId) async {
    final repo = _ref.read(glucoseRepositoryProvider);
    final existing = await _current(userId);
    await repo.saveProtocolState(userId, existing.copyWith(paused: false));
  }

  /// R10: desactivación completa — deja de pedir registros y oculta el
  /// módulo. NO borra el historial de lecturas (eso requiere una acción
  /// explícita y separada del usuario, fuera de alcance del MVP — ver
  /// informe de implementación, Riesgos y limitaciones).
  Future<void> deactivate(String userId) async {
    final repo = _ref.read(glucoseRepositoryProvider);
    final existing = await _current(userId);
    await repo.saveProtocolState(
      userId,
      existing.copyWith(protocolActive: false, paused: false),
    );
  }

  /// R7: registra un día sin registro en-ayunas — el llamador
  /// (GlucoseWindowState + un chequeo diario) decide cuándo incrementar
  /// vs. resetear a 0 al detectar un nuevo registro.
  Future<void> recordMissedDay(String userId, int missedStreak) async {
    final repo = _ref.read(glucoseRepositoryProvider);
    final existing = await _current(userId);
    await repo.saveProtocolState(
      userId,
      existing.copyWith(missedStreak: missedStreak),
    );
  }
}

final glucoseProtocolControllerProvider =
    Provider<GlucoseProtocolController>((ref) {
  return GlucoseProtocolController(ref);
});
