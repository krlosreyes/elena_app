// SPEC-132 — Bloque D: card autocontenida que muestra el estado del
// sync con Apple Health / Health Connect y permite al usuario:
//   - Conectar (si nunca dio permisos)
//   - Sincronizar ahora (si ya conectado)
//   - Instalar Health Connect (Android sin HC instalado)
//
// Se renderiza en ProfileScreen como una sección más, debajo de
// "Protocolo de ayuno" y antes de "Legal". En Web/Desktop el widget
// se auto-oculta retornando SizedBox.shrink().

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _HealthSyncCardState extends ConsumerState<HealthSyncCard> {
  @override
  void initState() {
    super.initState();
    // Refrescar estado de permisos al abrir el perfil. No pide al
    // usuario, solo consulta.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(healthAutoSyncControllerProvider.notifier)
          .refreshPermissionStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cortocircuito: si la plataforma no soporta el plugin (Web,
    // Desktop), no mostramos la sección.
    final service = ref.read(healthSyncServiceProvider);
    if (!service.isPlatformSupported) {
      return const SizedBox.shrink();
    }

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
      // Consultando permisos por primera vez.
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

    if (perm is HealthConnectNotInstalled) {
      return _buildInstallButton();
    }

    if (perm is HealthPermissionDenied) {
      return _buildConnectButton();
    }

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
        // SPEC-237: guía Samsung Health cuando sync Android regresa vacío.
        if (state.needsSamsungHealthGuide) ...[
          const SizedBox(height: 12),
          _buildSamsungHealthGuide(),
        ],
        const SizedBox(height: 12),
        SizedBox(
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
        ),
      ],
    );
  }

  // ─── Handlers ────────────────────────────────────────────────────

  Future<void> _handleConnect() async {
    final result = await ref
        .read(healthAutoSyncControllerProvider.notifier)
        .requestAuthorization();

    if (!mounted) return;
    if (result is HealthPermissionGranted) {
      // Disparar primer sync inmediato post-conexión.
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
    // Leyó datos pero no se importó nada: el plugin trajo $total
    // samples y todas fueron descartadas por reglas internas
    // (siestas <30min, <500 pasos/día, o ya existía un check-in
    // manual). Mostramos el detalle para que el usuario entienda.
    return 'Leídos $total registros · 0 importados '
        '(siestas <30min, días con <500 pasos o pesos ya registrados '
        'manualmente).';
  }

  /// SPEC-237: guía específica para usuarios con Samsung Galaxy Watch.
  /// Se muestra cuando el sync completó con permisos OK pero sin datos —
  /// la causa más frecuente es Samsung Health sin configurar para HC.
  Widget _buildSamsungHealthGuide() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFB923C).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.watch_outlined,
                size: 14,
                color: Color(0xFFFB923C),
              ),
              const SizedBox(width: 6),
              const Text(
                '¿Usas Samsung Galaxy Watch?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFB923C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Para sincronizar sueño y actividad del reloj:\n'
            '1. Abre Samsung Health\n'
            '2. Menú → Ajustes → Servicios conectados → Health Connect\n'
            '3. Activa Sueño y Actividad física\n'
            '4. Vuelve aquí y toca "Sincronizar ahora"',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
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
