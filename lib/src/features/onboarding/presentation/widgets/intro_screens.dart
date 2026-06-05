// SPEC-131: pantallas educativas para usuarios cero-contexto.
//
// SPEC-182 (2026-06-05): re-tono completo + 2 pantallas nuevas (Día
// Metabólico y Notificaciones con respaldo). El pivot "active coaching"
// requiere que el usuario salga del onboarding entendiendo dual scores,
// día metabólico y la naturaleza educativa de las notificaciones.
//
// Se muestran ANTES del onboarding tradicional (disclaimer, biometría,
// etc.) y SOLO para usuarios con profileStatus == newProfile. Los
// usuarios provenientes de MR (partialProfile) saltean estas pantallas
// — ya conocen el método.
//
// Estilo: solo texto + iconos Material (decisión de Carlos: cero
// dependencia de diseñador / assets nuevos / animaciones).

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

/// Pantalla 1 — Bienvenida. SPEC-182: re-tonada a "coach, no cuaderno".
class IntroWelcomeStep extends StatelessWidget {
  final bool isDark;
  const IntroWelcomeStep({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _IntroLayout(
      isDark: isDark,
      icon: Icons.menu_book_outlined,
      title: 'Te acompañamos a leer tu cuerpo',
      bodyParagraphs: const [
        'ElenaApp lee tu día y te devuelve coaching con respaldo '
            'científico. No es un cuaderno digital — es un coach.',
        'Cada notificación, cada número, cada gráfica trae una cita '
            'bibliográfica. Vas a saber por qué te decimos lo que '
            'te decimos.',
      ],
    );
  }
}

/// Pantalla 2 — Dos números. SPEC-182 + SPEC-170: prepara al usuario
/// para ver HOY motivacional + IMR longitudinal de fondo en el
/// Dashboard.
class IntroImrStep extends StatelessWidget {
  final bool isDark;
  const IntroImrStep({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _IntroLayout(
      isDark: isDark,
      icon: Icons.donut_small_outlined,
      title: 'Tus dos números',
      bodyParagraphs: const [
        'En el Dashboard vas a ver dos números: HOY e IMR. HOY es cómo '
            'viviste hoy — puede llegar a 100 cuando cumplís tus 5 '
            'pilares.',
        'IMR es tu base metabólica de fondo. Se mueve más lento, en '
            'semanas y meses. Esto es lo que importa cuando hablamos '
            'de cambios reales en tu cuerpo.',
        'Los dos son tuyos. Uno te empuja cada día, el otro te muestra '
            'el camino largo.',
      ],
    );
  }
}

/// Pantalla 3 — Datos privados. SPEC-182: ordena primero "qué hacemos
/// con los datos" (coaching), después "qué guardamos".
class IntroDataStep extends StatelessWidget {
  final bool isDark;
  const IntroDataStep({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _IntroLayout(
      isDark: isDark,
      icon: Icons.shield_outlined,
      title: 'Tus datos son tuyos',
      bodyParagraphs: const [
        'Te vamos a pedir peso, altura, edad, cintura y tus horarios '
            'de descanso. Con eso calculamos tu base y armamos tu '
            'coaching.',
        'Todo queda en tu cuenta privada. No vendemos ni compartimos. '
            'Podés borrar tu cuenta cuando quieras desde Perfil.',
      ],
    );
  }
}

/// SPEC-182 §RF-182-04 (2026-06-05): pantalla 4 — Día Metabólico.
/// Explica que el "día" se cierra cuando termina la ventana de comida,
/// no a medianoche calendárica. Alineado con SPEC-149.
class IntroMetabolicDayStep extends StatelessWidget {
  final bool isDark;
  const IntroMetabolicDayStep({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _IntroLayout(
      isDark: isDark,
      icon: Icons.brightness_3_outlined,
      title: 'El día empieza cuando empezás a ayunar',
      bodyParagraphs: const [
        'Tu día metabólico no se cierra a medianoche calendárica. Se '
            'cierra cuando termina tu ventana de comida y empezás tu '
            'próximo ayuno.',
        'Cuando eso pasa, te entregamos tu feedback del día con cita '
            'bibliográfica. Es el momento donde el coaching tiene '
            'sentido — no a las 23:59 cuando estás durmiendo.',
      ],
    );
  }
}

/// SPEC-182 §RF-182-05 (2026-06-05): pantalla 5 — Notificaciones con
/// respaldo. Muestra 3 ejemplos reales y solicita permisos en momento
/// educativo (no en cold start ciego como hacía SPEC-172 original).
class IntroNotificationsStep extends StatelessWidget {
  final bool isDark;
  final VoidCallback onActivate;
  final VoidCallback onSkip;

  const IntroNotificationsStep({
    super.key,
    required this.isDark,
    required this.onActivate,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.metabolicGreen;
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF475569);

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
            child: Icon(
              Icons.notifications_active_outlined,
              color: accent,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Te vamos a mandar mensajes con respaldo, no recordatorios '
          'vacíos',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Text(
            'Cada notificación que recibas trae cita bibliográfica. '
            'Así se ven algunas:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ),
        _ExamplePill(
          icon: Icons.auto_awesome_outlined,
          headline: '16 horas — Limpieza profunda',
          body:
              'Tu cuerpo empezó una limpieza profunda gracias a lo que '
              'estás haciendo hoy.',
          citation: '· Levine 2017',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _ExamplePill(
          icon: Icons.nights_stay_outlined,
          headline: '3 horas antes de dormir',
          body:
              'Si cerrás la ventana ahora, tu descanso te lo va a '
              'agradecer.',
          citation: '· Sutton 2018',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _ExamplePill(
          icon: Icons.water_drop_outlined,
          headline: 'Cortisol peak: hora ideal',
          body:
              'Hidratar durante el pico de cortisol mejora claridad '
              'mental.',
          citation: '· Adan 2012',
          isDark: isDark,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onActivate,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Activar coaching por notificaciones',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: onSkip,
            child: Text(
              'Más tarde',
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExamplePill extends StatelessWidget {
  const _ExamplePill({
    required this.icon,
    required this.headline,
    required this.body,
    required this.citation,
    required this.isDark,
  });

  final IconData icon;
  final String headline;
  final String body;
  final String citation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.metabolicGreen;
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.bgSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDefault : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  citation,
                  style: TextStyle(
                    color: textSecondary.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
