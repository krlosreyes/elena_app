// 17-jul (2da vuelta de feedback sobre el rediseño del Perfil): Carlos
// pidió que "Datos biométricos" deje de ser un acordeón inline y pase
// al mismo patrón de card colapsada + pantalla de detalle que ya se
// usa en el resto de la app (Progreso, Dashboard) — coherencia visual
// y menos scroll en la pantalla principal de Perfil.
//
// Todo el contenido y la lógica de edición (peso/cintura/cuello,
// recálculo de %grasa, lock semanal) se movieron tal cual desde
// `_ProfileBodyState` en profile_screen.dart — mismo comportamiento,
// solo cambia dónde vive.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/data_group_card.dart';
import 'package:elena_app/src/features/profile/application/biometric_lock_provider.dart';
import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';
import 'package:elena_app/src/features/progress/presentation/biometric_checkin_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class BiometricosDetailScreen extends ConsumerWidget {
  const BiometricosDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final biometryLock = ref.watch(biometricLockProvider);

    // 17-jul: el feedback de guardado (antes en ProfileScreen, visible
    // porque la edición pasaba por un bottom sheet sobre esa misma
    // pantalla) se replica acá — ahora la edición ocurre en esta
    // pantalla propia, así que el snackbar debe salir de acá para que
    // el usuario lo vea sin tener que volver atrás.
    ref.listen<ProfileEditState>(profileControllerProvider, (prev, next) {
      if (next.savedSuccessfully && !(prev?.savedSuccessfully ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
        ref.read(profileControllerProvider.notifier).clearFeedback();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
        ref.read(profileControllerProvider.notifier).clearFeedback();
      }
    });

    final isSaving = ref.watch(
      profileControllerProvider.select((s) => s.isSaving),
    );

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
          'Datos biométricos',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF10B981)),
                ),
              ),
            ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Body(user: user, biometryLock: biometryLock);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.user, required this.biometryLock});

  final UserModel user;
  final BiometricLockState biometryLock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          // 2026-11-04: una medición por semana — peso, cintura y cuello
          // se registran juntos en el mismo formulario.
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: biometryLock.isLocked
                  ? null
                  : () => showBiometricCheckInSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.metabolicGreen,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                biometryLock.isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.straighten_rounded,
                size: 18,
                color: biometryLock.isLocked
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFF032A22),
              ),
              label: Text(
                biometryLock.isLocked
                    ? biometryLock.unlockLabel
                    : 'Actualizar medidas',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: biometryLock.isLocked
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF032A22),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Text(
              'Peso, cintura y cuello se registran juntos una vez por semana, '
              'para que tu IMR refleje cambios reales y no variaciones del día.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          ProfileDataGroupCard(
            rows: [
              ProfileDataRow.editable(
                label: 'Nombre',
                value: user.name,
                onTap: () => context.push('/profile/cuenta'),
              ),
              ProfileDataRow.editable(
                label: 'Edad',
                value: '${user.age} años',
                onTap: () => context.push('/profile/cuenta'),
              ),
              ProfileDataRow.editable(
                label: 'Sexo',
                value: user.gender == 'M' ? 'Masculino' : 'Femenino',
                onTap: () => context.push('/profile/cuenta'),
              ),
              ProfileDataRow.editable(
                label: 'Estatura',
                value: '${user.height.toInt()} cm',
                onTap: () => context.push('/profile/cuenta'),
              ),
              // 17-jul (P0, propuesta "un Perfil que da orgullo abrir"):
              // las condiciones médicas viven acá, no en el subtítulo de
              // identidad — ver profile_identity_card.dart.
              ProfileDataRow.readonly(
                  'Condiciones', user.pathologies.join(' · ')),
              ProfileDataRow.readonly('Peso', '${user.weight.toStringAsFixed(1)} kg'),
              ProfileDataRow.readonly(
                  'Cintura', '${user.waistCircumference?.toInt() ?? 0} cm'),
              ProfileDataRow.readonly(
                  'Cuello', '${user.neckCircumference?.toInt() ?? 0} cm'),
              ProfileDataRow.info(
                label: '% Grasa est.',
                value: _formatBodyFat(user.bodyFatPercentage),
                tag: 'confianza ${user.confidenceLevel}',
                tagColor: _confidenceColor(user.confidenceLevel),
                onInfoTap: () => _showBodyFatExplanation(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// SPEC-92: explicación de por qué el % grasa no es editable manualmente.
  void _showBodyFatExplanation(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Por qué no puedo editar este valor?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'El % de grasa corporal se calcula automáticamente a partir '
              'de tu cintura, cuello y altura usando la fórmula US Navy '
              '(validada clínicamente).\n\n'
              'Para actualizarlo, edita cualquiera de esas medidas. Así '
              'evitamos divergencias entre lo que el sistema mide y lo '
              'que el usuario afirma — y el IMR refleja tu estructura '
              'corporal real.',
              style: TextStyle(
                color: Color(0xFFB6C3D1),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'ENTENDIDO',
                  style: TextStyle(
                    color: Color(0xFF00C49A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBodyFat(double? value) {
    if (value == null) return 'Sin medir';
    return '${value.toStringAsFixed(1)}%';
  }

  Color _confidenceColor(String level) {
    switch (level) {
      case 'ALTA':
        return AppColors.metabolicGreen;
      case 'MEDIA':
        return const Color(0xFFEAB308);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
