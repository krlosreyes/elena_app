import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/models/user_model.dart';
import '../../../profile/data/user_repository.dart';
import '../../../profile/application/user_controller.dart';


class FoodPreferencesModal extends ConsumerStatefulWidget {
  final VoidCallback? onSave;
  final UserModel? user;
  const FoodPreferencesModal({super.key, this.onSave, this.user});

  @override
  ConsumerState<FoodPreferencesModal> createState() =>
      _FoodPreferencesModalState();
}

class _FoodPreferencesModalState extends ConsumerState<FoodPreferencesModal> {
  DietaryPreference _selected = DietaryPreference.omnivore;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PREFERENCIAS NUTRICIONALES',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.primary,
                  ),
                ),
                // Removido botón de cierre para cumplir Regla de Oro (No omitible durante el tour)
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Elena ajustará tus sugerencias de comida basándose en esta configuración técnica.',
              style:
                  GoogleFonts.publicSans(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildOption(
                DietaryPreference.omnivore, 'OMNÍVORO', 'Sin restricciones'),
            _buildOption(DietaryPreference.keto, 'CETOGÉNICO (KETO)',
                'Alto en grasas, bajo en carbos'),
            _buildOption(DietaryPreference.lowCarb, 'LOW CARB',
                'Enfoque en carbohidratos lentos'),
            _buildOption(
                DietaryPreference.vegan, 'VEGANO', 'Plant-based exclusively'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: const BeveledRectangleBorder(),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        'GUARDAR PERFIL TÉCNICO',
                        style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.w900),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(DietaryPreference pref, String title, String subtitle) {
    final bool isSelected = _selected == pref;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = pref);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.black26,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.jetBrainsMono(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.publicSans(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final user =
          widget.user ?? ref.read(currentUserStreamProvider).valueOrNull;

      if (user != null) {
        final updated = user.copyWith(dietaryPreference: _selected);
        debugPrint(
            '🍎 MODAL: Guardando preferencia ${_selected.name} para ${user.uid}');
        await ref.read(userRepositoryProvider).saveUser(updated);

        if (mounted && widget.onSave != null) {
          widget.onSave!();
        }
      } else {
        debugPrint(
            '⚠️ MODAL: No se encontró el usuario para guardar preferencias.');
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
