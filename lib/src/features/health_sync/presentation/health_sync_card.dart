// SPEC-132 — Bloque D: card autocontenida que muestra el estado del
// sync con Apple Health / Health Connect y permite al usuario:
//   - Conectar (si nunca dio permisos)
//   - Sincronizar ahora (si ya conectado)
//   - Instalar Health Connect (Android sin HC instalado)
//
// SPEC-238: guía Samsung simplificada — 1 botón que abre Samsung Health
// directamente + sync automático al volver.
//
// Se renderiza en ProfileScreen como una sección más.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/health_sync/application/health_auto_sync_controller.dart';
import 'package:elena_app/src/features/health_sync/application/health_import_service.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_providers.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class HealthSyncCard extends ConsumerStatefulWidget {
  const HealthSyncCard({super.key});

  @override
  ConsumerState<HealthSyncCard> createState() => _HealthSyncCardState();
}

class _HealthSyncCardState extends ConsumerState<HealthSyncCard>
    with WidgetsBindingObserver {
  // SPEC-238: cuando el usuario va a Samsung Health y vuelve, disparamos
  // un sync inmediato sin esperar el debounce de 15 min.
  bool _openedSamsungHealth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(healthAutoSyncControllerProvider.notifier)
          .refreshPermissionStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    // Al volver de Samsung Health, sync inmediato (bypass debounce).
    if (appState == AppLifecycleState.resumed && _openedSamsungHealth) {
      _openedSamsungHealth = false;
      final user = ref.read(currentUserStreamProvider).value;
      if (user != null) {
        ref
            .read(healthAutoSyncControllerProvider.notifier)
            .runNow(userId: user.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(healthSyncServiceProvider);
    if (!service.isPlatformSupported) return const SizedBox.shrink();

    final state = ref.watch(healthAutoSyncControllerProvider);
    final perm = state.permissionStatus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(perm),
          const SizedBox(height: 12),
          _buildBody(state, perm),
        ],
      ),
    );
  }

  // ─── Sub-builds ──────────────────────────────────────────────────

  Widget _buildHeader(HealthPermissionStatus? perm) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.metabolicGreen.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.favorite_outline,
            size: 20,
            color: AppColors.metabolicGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apple Health · Health Connect',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusLabel(perm),
                style: TextStyle(
                  fontSize: 12,
                  color: _statusColor(perm),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(HealthAutoSyncState state, HealthPermissionStatus? perm) {
    if (perm == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            SizedBox(width: 10),
            Text(
              'Verificando…',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (perm is HealthPermissionUnavailable) {
      return Text(
        perm.reason ?? 'No disponible en este dispositivo.',
        style: const TextStyle(fontSize: 13, color: Colors.white60),
      );
    }

    if (perm is HealthConnectNotInstalled) return _buildInstallButton();
    if (perm is HealthPermissionDenied) return _buildConnectButton();

    // Granted (o Partial) — mostrar última sync + botón manual.
    return _buildSyncStatusAndButton(state);
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.metabolicGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _handleConnect,
        child: const Text(
          'Conectar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildInstallButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Connect no está instalado en este dispositivo.',
          style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.metabolicGreen,
              side: BorderSide(color: AppColors.metabolicGreen),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              ref.read(healthSyncServiceProvider).openHealthConnectInstall();
            },
            child: const Text('Instalar Health Connect'),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatusAndButton(HealthAutoSyncState state) {
    final isRunning = state.isRunning;
    final lastRun = state.lastRunAt;
    final lastResult = state.lastResult;
    final lastImport = state.lastImport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatLastRun(lastRun, isRunning),
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        if (lastImport != null && lastImport.totalImported > 0) ...[
          const SizedBox(height: 4),
          Text(
            _formatImportSummary(lastImport),
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ] else if (lastResult != null &&
            lastImport != null &&
            lastImport.totalImported == 0) ...[
          const SizedBox(height: 4),
          Text(
            _formatNothingImported(lastResult, lastImport),
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
        if (lastResult != null && lastResult.hasErrors) ...[
          const SizedBox(height: 4),
          Text(
            _formatErrors(lastResult),
            style: const TextStyle(fontSize: 12, color: Color(0xFFFB923C)),
          ),
        ],
        // SPEC-238: guía Samsung simplificada — 1 botón, sync al volver.
        if (state.needsSamsungHealthGuide) ...[
          const SizedBox(height: 12),
          _buildSamsungHealthGuide(isRunning),
        ],
        if (!state.needsSamsungHealthGuide) ...[
          const SizedBox(height: 12),
          _buildSyncNowButton(isRunning),
        ],
      ],
    );
  }

  /// SPEC-238: guía Samsung rediseñada.
  /// UN botón que lleva al usuario directamente a Samsung Health.
  /// Al volver, `didChangeAppLifecycleState` dispara el sync automático.
  Widget _buildSamsungHealthGuide(bool isRunning) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFB923C).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: const [
              Icon(Icons.watch_outlined, size: 15, color: Color(0xFFFB923C)),
              SizedBox(width: 7),
              Text(
                'Tu reloj Samsung no sincroniza sueño',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFB923C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Descripción corta
          const Text(
            'Activa "Sueño" en Samsung Health → '
            'Health Connect para que los datos lleguen aquí.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          // Botón de acción principal
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFB923C),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isRunning ? null : _handleOpenSamsungHealth,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text(
                'Abrir Samsung Health',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Confirmación de lo que pasa al volver
          const Text(
            'Al volver, sincronizaremos automáticamente.',
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncNowButton(bool isRunning) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isRunning ? null : _handleSyncNow,
        child: isRunning
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  SizedBox(width: 10),
                  Text('Sincronizando…'),
                ],
              )
            : const Text('Sincronizar ahora'),
      ),
    );
  }

  // ─── Handlers ────────────────────────────────────────────────────

  Future<void> _handleConnect() async {
    final result = await ref
        .read(healthAutoSyncControllerProvider.notifier)
        .requestAuthorization();

    if (!mounted) return;
    if (result is HealthPermissionGranted) {
      final user = ref.read(currentUserStreamProvider).value;
      if (user != null) {
        // ignore: use_build_context_synchronously
        await ref
            .read(healthAutoSyncControllerProvider.notifier)
            .runNow(userId: user.id);
      }
    } else if (result is HealthPermissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitamos los permisos para importar tus datos. '
            'Podés activarlos desde Ajustes > Salud.',
          ),
        ),
      );
    }
  }

  Future<void> _handleSyncNow() async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;
    await ref
        .read(healthAutoSyncControllerProvider.notifier)
        .runNow(userId: user.id);
  }

  /// SPEC-238: abre Samsung Health directamente via AndroidIntent.
  /// Fallback: Health Connect settings si Samsung Health no está instalado.
  /// Setea `_openedSamsungHealth = true` para disparar sync al volver.
  Future<void> _handleOpenSamsungHealth() async {
    _openedSamsungHealth = true;
    if (kIsWeb || !Platform.isAndroid) return;

    // Intento 1: URL scheme nativo de Samsung Health.
    try {
      // ignore: avoid_print
      print('🩺 SAMSUNG OPEN: intentando shealth://');
      const intent1 = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'shealth://home',
        package: 'com.sec.android.app.shealth',
        flags: <int>[0x10000000],
      );
      await intent1.launch();
      // ignore: avoid_print
      print('🩺 SAMSUNG OPEN: shealth:// OK');
      return;
    } catch (e) {
      // ignore: avoid_print
      print('🩺 SAMSUNG OPEN: shealth:// falló — $e');
    }

    // Intento 2: intent MAIN + category LAUNCHER (forma estándar de abrir apps).
    try {
      // ignore: avoid_print
      print('🩺 SAMSUNG OPEN: intentando MAIN/LAUNCHER');
      const intent2 = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: 'com.sec.android.app.shealth',
        flags: <int>[0x10000000],
      );
      await intent2.launch();
      // ignore: avoid_print
      print('🩺 SAMSUNG OPEN: MAIN/LAUNCHER OK');
      return;
    } catch (e) {
      // ignore: avoid_print
      print('🩺 SAMSUNG OPEN: MAIN/LAUNCHER falló — $e');
    }

    // Fallback final: Health Connect settings.
    // ignore: avoid_print
    print('🩺 SAMSUNG OPEN: fallback → Health Connect');
    await ref.read(healthSyncServiceProvider).openHealthConnectSettings();
  }

  // ─── Format helpers ──────────────────────────────────────────────

  String _statusLabel(HealthPermissionStatus? perm) {
    if (perm == null) return 'Verificando…';
    return switch (perm) {
      HealthPermissionGranted() => 'Conectado',
      HealthPermissionPartial() => 'Conectado (parcial)',
      HealthPermissionDenied() => 'No conectado',
      HealthPermissionUnavailable() => 'No disponible',
      HealthConnectNotInstalled() => 'Falta Health Connect',
    };
  }

  Color _statusColor(HealthPermissionStatus? perm) {
    if (perm == null) return Colors.white60;
    return switch (perm) {
      HealthPermissionGranted() => AppColors.metabolicGreen,
      HealthPermissionPartial() => const Color(0xFFFFD700),
      HealthPermissionDenied() => Colors.white60,
      HealthPermissionUnavailable() => Colors.white38,
      HealthConnectNotInstalled() => const Color(0xFFFB923C),
    };
  }

  String _formatLastRun(DateTime? lastRun, bool isRunning) {
    if (isRunning) return 'Sincronizando ahora…';
    if (lastRun == null) return 'Aún no se ha sincronizado.';
    final diff = DateTime.now().difference(lastRun);
    if (diff.inMinutes < 1) return 'Última sync: hace instantes';
    if (diff.inMinutes < 60) return 'Última sync: hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Última sync: hace ${diff.inHours} h';
    return 'Última sync: hace ${diff.inDays} días';
  }

  String _formatNothingImported(
    HealthSyncResult result,
    HealthImportSummary summary,
  ) {
    final total = result.totalSamples;
    if (total == 0) {
      return 'No encontramos datos en Apple Health · Health Connect '
          'para los últimos 7 días.';
    }
    return 'Leídos $total registros · 0 importados '
        '(siestas <30min, días con <500 pasos o pesos ya registrados '
        'manualmente).';
  }

  String _formatImportSummary(HealthImportSummary s) {
    final parts = <String>[];
    if (s.weightsImported > 0) parts.add('${s.weightsImported} peso(s)');
    if (s.sleepSessionsImported > 0) {
      parts.add('${s.sleepSessionsImported} sueño(s)');
    }
    if (s.workoutsImported > 0) {
      parts.add('${s.workoutsImported} entrenamiento(s)');
    }
    if (s.stepsActivitiesImported > 0) {
      parts.add('${s.stepsActivitiesImported} actividad(es)');
    }
    if (parts.isEmpty) return '';
    return 'Importado: ${parts.join(' · ')}';
  }

  String _formatErrors(HealthSyncResult result) {
    final names = result.errors.keys.map((m) => m.label).join(', ');
    return 'No se pudo leer: $names';
  }
}
