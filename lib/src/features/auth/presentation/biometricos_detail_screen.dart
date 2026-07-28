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
import 'package:elena_app/src/features/auth/presentation/widgets/edit_biometry_value_sheet.dart';
import 'package:elena_app/src/features/profile/application/biometric_lock_provider.dart';
import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';
import 'package:elena_app/src/features/profile/domain/biometry_recalc.dart';
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
          if (biometryLock.isLocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155).withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${biometryLock.unlockLabel}. El IMR Base se '
                        'estabiliza 6 días para reflejar cambios reales. '
                        'Tu Día de Permitidos también cierra el ciclo.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ProfileDataGroupCard(
            rows: [
              ProfileDataRow.readonly('Nombre', user.name),
              ProfileDataRow.readonly('Edad', '${user.age} años'),
              ProfileDataRow.readonly(
                  'Género', user.gender == 'M' ? 'Masculino' : 'Femenino'),
              ProfileDataRow.readonly('Estatura', '${user.height.toInt()} cm'),
              // 17-jul (P0, propuesta "un Perfil que da orgullo abrir"):
              // las condiciones médicas viven acá, no en el subtítulo de
              // identidad — ver profile_identity_card.dart.
              ProfileDataRow.readonly(
                  'Condiciones', user.pathologies.join(' · ')),
              ProfileDataRow.editable(
                label: 'Peso',
                value: '${user.weight.toInt()} kg',
                onTap: biometryLock.isLocked
                    ? () => _showBiometryLockedSnackbar(context, biometryLock)
                    : () => _editWeight(context, ref, user, biometryLock),
              ),
              ProfileDataRow.editable(
                label: 'Cintura',
                value: '${user.waistCircumference?.toInt() ?? 0} cm',
                onTap: biometryLock.isLocked
                    ? () => _showBiometryLockedSnackbar(context, biometryLock)
                    : () => _editWaist(context, ref, user, biometryLock),
              ),
              ProfileDataRow.editable(
                label: 'Cuello',
                value: '${user.neckCircumference?.toInt() ?? 0} cm',
                onTap: biometryLock.isLocked
                    ? () => _showBiometryLockedSnackbar(context, biometryLock)
                    : () => _editNeck(context, ref, user, biometryLock),
              ),
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

  // ── Edición biométrica ──────────────────────────────────────────────
  // SPEC-92: cada edit de peso/cintura/cuello recalcula bodyFat con
  // `BiometryRecalc.recompute` antes de persistir.

  Future<void> _applyBiometryEdit(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    BiometricLockState lock, {
    double? newWeight,
    double? newWaist,
    double? newNeck,
  }) async {
    if (lock.isLocked) {
      _showBiometryLockedSnackbar(context, lock);
      return;
    }
    final effectiveWeight = newWeight ?? user.weight;
    final effectiveWaist = newWaist ?? user.waistCircumference;
    final effectiveNeck = newNeck ?? user.neckCircumference;

    final recalc = BiometryRecalc.recompute(
      weightKg: effectiveWeight,
      heightCm: user.height,
      waistCm: effectiveWaist,
      neckCm: effectiveNeck,
      gender: user.gender,
    );

    if (recalc.isCoherent && recalc.bodyFatPercentage != null) {
      await ref.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: user,
            weight: newWeight,
            waistCircumference: newWaist,
            neckCircumference: newNeck,
            bodyFatPercentage: recalc.bodyFatPercentage,
          );
      return;
    }

    await ref.read(profileControllerProvider.notifier).updateBiometry(
          currentUser: user,
          weight: newWeight,
          waistCircumference: newWaist,
          neckCircumference: newNeck,
        );
    if (context.mounted) _showIncoherenceNotice(context);
  }

  Future<void> _editWeight(BuildContext context, WidgetRef ref, UserModel user,
      BiometricLockState lock) async {
    final value = await EditBiometryValueSheet.show(
      context,
      title: 'Editar peso',
      fieldLabel: 'Peso corporal actual',
      unit: 'kg',
      initialValue: user.weight,
      minValue: 30,
      maxValue: 250,
    );
    if (value != null && context.mounted) {
      await _applyBiometryEdit(context, ref, user, lock, newWeight: value);
    }
  }

  Future<void> _editWaist(BuildContext context, WidgetRef ref, UserModel user,
      BiometricLockState lock) async {
    final value = await EditBiometryValueSheet.show(
      context,
      title: 'Editar cintura',
      fieldLabel: 'Circunferencia de cintura (medida a la altura del ombligo)',
      unit: 'cm',
      initialValue: user.waistCircumference ?? 80,
      minValue: 50,
      maxValue: 200,
    );
    if (value != null && context.mounted) {
      await _applyBiometryEdit(context, ref, user, lock, newWaist: value);
    }
  }

  Future<void> _editNeck(BuildContext context, WidgetRef ref, UserModel user,
      BiometricLockState lock) async {
    final value = await EditBiometryValueSheet.show(
      context,
      title: 'Editar cuello',
      fieldLabel: 'Circunferencia del cuello',
      unit: 'cm',
      initialValue: user.neckCircumference ?? 38,
      minValue: 25,
      maxValue: 70,
    );
    if (value != null && context.mounted) {
      await _applyBiometryEdit(context, ref, user, lock, newNeck: value);
    }
  }

  void _showIncoherenceNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Las medidas no son coherentes. El % grasa no se actualizó '
          '— revisa cintura, cuello y altura.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showBiometryLockedSnackbar(
      BuildContext context, BiometricLockState lock) {
    final msg = lock.unlocksAt != null
        ? 'Datos biométricos bloqueados — ${lock.unlockLabel}. '
            'Tu IMR Base se estabiliza durante 6 días para reflejar '
            'cambios reales, no fluctuaciones diarias.'
        : 'Datos biométricos bloqueados. Vuelve en 6 días o cierra tu '
            'semana con un Día de Permitidos.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF334155),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
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
