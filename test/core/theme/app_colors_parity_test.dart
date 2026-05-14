// SPEC-89 §6 — paridad de la paleta canónica con el sitio Metamorfosis
// Real. Si el sitio modifica un hex en `global.css → @theme`, hay que
// actualizar `AppColors` en la app y este test pasa a verde de nuevo.

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-89 — AppColors paridad con sitio Metamorfosis Real', () {
    test('backgrounds matchean los hex canónicos', () {
      expect(AppColors.bgBase, const Color(0xFF020617));
      expect(AppColors.bgSurface, const Color(0xFF0C1422));
      expect(AppColors.bgElevated, const Color(0xFF1A2332));
    });

    test('text matchea los hex canónicos', () {
      expect(AppColors.textPrimary, const Color(0xFFF1F5F9));
      expect(AppColors.textSecondary, const Color(0xFF94A3B8));
      expect(AppColors.textMuted, const Color(0xFF64748B));
    });

    test('accent matchea los hex canónicos', () {
      expect(AppColors.accent, const Color(0xFF00C49A));
      expect(AppColors.accentStrong, const Color(0xFF00B389));
    });

    test('status colors matchean los hex canónicos', () {
      expect(AppColors.statusGood, const Color(0xFF10B981));
      expect(AppColors.statusWarn, const Color(0xFFF59E0B));
      expect(AppColors.statusBad, const Color(0xFFEF4444));
    });

    test('bordes son opacidades de blanco', () {
      expect(AppColors.borderSubtle, const Color(0x0AFFFFFF));
      expect(AppColors.borderDefault, const Color(0x14FFFFFF));
      expect(AppColors.borderStrong, const Color(0x1FFFFFFF));
    });
  });

  group('SPEC-89 — aliases legacy apuntan a tokens canónicos', () {
    test('metabolicGreen y optimalCyan apuntan a accent', () {
      expect(AppColors.metabolicGreen, AppColors.accent);
      expect(AppColors.optimalCyan, AppColors.accent);
    });

    test('backgroundDark/background apuntan a bgBase', () {
      expect(AppColors.backgroundDark, AppColors.bgBase);
      expect(AppColors.background, AppColors.bgBase);
    });

    test('surfaceDark/surface apuntan a bgSurface', () {
      expect(AppColors.surfaceDark, AppColors.bgSurface);
      expect(AppColors.surface, AppColors.bgSurface);
    });

    test('circadianAmber apunta a statusWarn', () {
      expect(AppColors.circadianAmber, AppColors.statusWarn);
    });

    test('border apunta a borderDefault', () {
      expect(AppColors.border, AppColors.borderDefault);
    });
  });
}
