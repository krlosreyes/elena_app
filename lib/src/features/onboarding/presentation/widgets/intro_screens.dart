// SPEC-131: pantallas educativas para usuarios cero-contexto.
//
// Se muestran ANTES del onboarding tradicional (disclaimer, biometría,
// etc.) y SOLO para usuarios con profileStatus == newProfile. Los
// usuarios provenientes de MR (partialProfile) saltean estas pantallas
// — ya conocen el método.
//
// Estilo: solo texto + iconos Material (decisión de Carlos: cero
// dependencia de diseñador / assets nuevos / animaciones). Una
// iteración futura puede agregar ilustraciones SVG cuando haya
// diseñador disponible.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

/// Pantalla 1 — Bienvenida. Presenta ElenaApp y los 5 pilares.
class IntroWelcomeStep extends StatelessWidget {
  final bool isDark;
  const IntroWelcomeStep({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _IntroLayout(
      isDark: isDark,
      icon: Icons.eco_outlined,
      title: 'Te damos la bienvenida',
      bodyParagraphs: const [
        'ElenaApp es tu compañera para entender y mejorar tu salud '
            'metabólica desde 5 pilares verificables: ayuno, sueño, '
            'hidratación, ejercicio y nutrición.',
        'Tu cuerpo ya tiene la información — la app te ayuda a leerla '
            'y a actuar sobre ella.',
      ],
    );
  }
}

/// Pantalla 2 — Qué es IMR. Explica el indicador único.
class IntroImrStep extends StatelessWidget {
  final bool isDark;
  const IntroImrStep({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _IntroLayout(
      isDark: isDark,
      icon: Icons.speed_outlined,
      title: 'Tu IMR es un número que resume tu día',
      bodyParagraphs: const [
        'El Indicador Metabólico Real (IMR) es un puntaje de 0 a 100 '
            'que refleja qué tan alineado estás con tu biología.',
        'Sube cuando duermes bien, comes platos saludables, ayunas '
            'con respeto a tu ritmo circadiano y te mueves. Baja '
            'cuando te alejas.',
        'Hoy registramos para que mañana puedas mejorar.',
      ],
    );
  }
}

/// Pantalla 3 — Por qué los datos. Transparencia y privacidad.
class IntroDataStep extends StatelessWidget {
  final bool isDark;
  const IntroDataStep({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _IntroLayout(
      isDark: isDark,
      icon: Icons.shield_outlined,
      title: 'Datos que pedimos, y por qué',
      bodyParagraphs: const [
        'Para calcular tu IMR necesitamos algunos datos personales: '
            'peso, altura, edad, cintura y cuello (composición '
            'corporal), tus horarios circadianos (para alinear '
            'comidas) y tus hábitos de ayuno.',
        'Todo queda en tu cuenta privada. No vendemos ni compartimos '
            'tu información con terceros. Podés eliminar tu cuenta '
            'cuando quieras desde tu perfil.',
      ],
    );
  }
}

// ── Layout interno común a las 3 pantallas ──────────────────────────

class _IntroLayout extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final List<String> bodyParagraphs;

  const _IntroLayout({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.bodyParagraphs,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.metabolicGreen;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 48),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                isDark ? AppColors.textPrimary : const Color(0xFF1E293B),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 20),
        for (final paragraph in bodyParagraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              paragraph,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : const Color(0xFF475569),
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
      ],
    );
  }
}
