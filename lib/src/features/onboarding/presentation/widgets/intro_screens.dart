// SPEC-247 (2026-07-07): Onboarding por Transformación.
// Rediseño completo de las pantallas educativas con principios de influencia
// anclados a la identidad científica de ElenaApp (ver ENGAGEMENT_ANALYSIS_2026_07.md).
//
// Pantallas activas:
//   100 — IntroWelcomeStep    (Identidad: Unidad + Autoridad)
//   105 — IntroProtocolStep   (Compromiso y coherencia) ← NUEVA
//   101 — IntroInsightStep    (Reciprocidad + Autoridad) ← sustituye IntroImrStep
//   104 — IntroNotificationsStep (Prueba social + activar) ← rediseñada
//
// Pantallas eliminadas:
//   102 — IntroDataStep       → privacidad absorbida en header de Biometría (onboarding_screen)
//   103 — IntroMetabolicDayStep → movida a coaching card post-Day-1 (SPEC-249, deferred)
//
// Reglas de copy:
//   - Español neutro LatAm. CERO voseo (no vos/acá/tenés/empezás/cumplís).
//   - Solo iconos Material. Sin assets ni dependencias externas.
//   - Cada claim científico lleva su cita.

import 'package:flutter/material.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

// ── PASO 100 — Identidad ─────────────────────────────────────────────
// Principios: Unidad + Autoridad
// El usuario entiende que esta app es diferente a una dieta genérica.
// Las citation pills anclan la credibilidad en la primera pantalla.

class IntroWelcomeStep extends StatelessWidget {
  final bool isDark;
  const IntroWelcomeStep({super.key, required this.isDark});

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
            child: Icon(Icons.biotech_outlined, color: accent, size: 48),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'La mayoría sigue dietas.\nTú vas a entender tu metabolismo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Las dietas te dicen qué comer. ElenaApp te muestra por qué '
          'tu cuerpo responde como responde — y qué hacer al respecto.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textSecondary,
            fontSize: 15,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Cada número, cada notificación y cada gráfica tiene una cita '
          'científica verificable. No te pedimos fe — te damos las fuentes.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textSecondary,
            fontSize: 15,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 28),
        _CitationPill(
          icon: Icons.menu_book_outlined,
          text: 'NEJM · Metabolismo circadiano',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _CitationPill(
          icon: Icons.science_outlined,
          // Fix P0 (validación de ejecución real, 23-jul-2026): el Nobel de
          // Fisiología o Medicina 2016 por el descubrimiento de los
          // mecanismos de la autofagia fue para Yoshinori Ohsumi, no para
          // Beth Levine (que nunca recibió el Nobel) ni en 2017.
          text: 'Ohsumi 2016 · Autofagia y ayuno  (Nobel de Medicina)',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _CitationPill(
          icon: Icons.nightlight_outlined,
          text: 'AASM · Sueño y regulación hormonal',
          isDark: isDark,
        ),
      ],
    );
  }
}

// ── PASO 105 — Protocolo ─────────────────────────────────────────────
// Principio: Compromiso y coherencia
// El usuario elige un protocolo clínico (no una "meta genérica").
// Ese compromiso lo ancla al modelo metabólico desde el primer gesto.

class IntroProtocolStep extends StatelessWidget {
  final bool isDark;
  final String selectedProtocol;
  final ValueChanged<String> onProtocolSelected;

  const IntroProtocolStep({
    super.key,
    required this.isDark,
    required this.selectedProtocol,
    required this.onProtocolSelected,
  });

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.metabolicGreen.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              color: AppColors.metabolicGreen,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Elige tu punto de partida',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Los tres protocolos tienen respaldo clínico. '
          'La diferencia es el tiempo de ayuno diario.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textSecondary,
            fontSize: 15,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 28),
        // SPEC-257 LIMPIEZA: el id de esta card era '14:8' — no suma 24h
        // (14+8=22) y, más grave, no coincide con ningún string del
        // catálogo real (`FastingEligibility.ladder`, `ProtocolSelectorSheet`,
        // `FastingSchedule.novatoTierProtocols`). Un usuario que elegía
        // "14/10" en su primer gesto de onboarding quedaba persistido con
        // un protocolo fantasma: invisible para el gate médico, la
        // escalera de auto-progresión y el mecanismo de días de descanso
        // programado (§3.1) — exactamente el usuario Novato al que ese
        // mecanismo apunta. El label ya decía "14/10" — se corrige el id
        // para que coincida.
        _ProtocolCard(
          id: '14:10',
          title: '14/10',
          subtitle: '14 horas de ayuno · 10 de alimentación',
          description: 'Para empezar. Extiende la noche y construye el hábito.',
          isSelected: selectedProtocol == '14:10',
          onTap: () => onProtocolSelected('14:10'),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _ProtocolCard(
          id: '16:8',
          title: '16/8',
          subtitle: '16 horas de ayuno · 8 de alimentación',
          description: 'El más estudiado. El 70% de las personas empieza aquí.',
          isSelected: selectedProtocol == '16:8',
          onTap: () => onProtocolSelected('16:8'),
          isDark: isDark,
          recommended: true,
        ),
        const SizedBox(height: 12),
        _ProtocolCard(
          id: '18:6',
          title: '18/6',
          subtitle: '18 horas de ayuno · 6 de alimentación',
          description:
              'Avanzado. Para quienes ya construyeron la base metabólica.',
          isSelected: selectedProtocol == '18:6',
          onTap: () => onProtocolSelected('18:6'),
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        Text(
          'Puedes cambiar de protocolo en cualquier momento desde tu perfil.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textSecondary.withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── PASO 101 — Insight personalizado ────────────────────────────────
// Principios: Reciprocidad + Autoridad
// Da valor ANTES de pedir datos. El timeline adapta al protocolo elegido.
// El usuario sale de esta pantalla sabiendo qué pasa en su cuerpo y por qué.

class IntroInsightStep extends StatelessWidget {
  final bool isDark;
  // Protocolo elegido en el paso 105. Determina el timeline mostrado.
  final String protocol;

  const IntroInsightStep({
    super.key,
    required this.isDark,
    this.protocol = '16:8',
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF475569);

    final title = _titleFor(protocol);
    final rows = _timelineFor(protocol);
    final footer = _footerFor(protocol);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.metabolicGreen.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insights_outlined,
              color: AppColors.metabolicGreen,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 24),
        // Timeline
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isDark ? AppColors.borderDefault : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                _TimelineRow(
                  hour: rows[i].hour,
                  icon: rows[i].icon,
                  text: rows[i].text,
                  citation: rows[i].citation,
                  isDark: isDark,
                  isLast: i == rows.length - 1,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          footer,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  static String _titleFor(String protocol) {
    switch (protocol) {
      case '14:10':
        return 'Esto pasa en tu cuerpo\ndurante 14 horas de ayuno';
      case '18:6':
        return 'El protocolo avanzado con\nmás evidencia en pérdida de grasa';
      case '16:8':
      default:
        return 'Esto pasa en tu cuerpo\ndurante un ayuno de 16 horas';
    }
  }

  static String _footerFor(String protocol) {
    switch (protocol) {
      case '14:10':
        return 'Estos eventos son automáticos. '
            '14/10 es el protocolo ideal para construir el hábito. '
            'ElenaApp te avisa en cada hito.';
      case '18:6':
        return 'Estos eventos son automáticos. '
            '18/6 requiere que tu sistema digestivo esté adaptado. '
            'ElenaApp ajusta el coaching si el patrón necesita cambio.';
      case '16:8':
      default:
        return 'Estos eventos son automáticos. '
            'Tu trabajo es darle el tiempo necesario. '
            'ElenaApp te avisa en cada hito.';
    }
  }

  static List<_TimelineData> _timelineFor(String protocol) {
    switch (protocol) {
      case '14:10':
        return [
          _TimelineData(
            hour: 'Hora 0',
            icon: '🔒',
            text: 'Cierras la ventana. Tu cuerpo usa glucosa almacenada.',
          ),
          _TimelineData(
            hour: 'Hora 6',
            icon: '🔥',
            text: 'La insulina baja. El cuerpo empieza a acceder a reservas de grasa.',
            citation: '· Cahill, 1966 — NEJM',
          ),
          _TimelineData(
            hour: 'Hora 12',
            icon: '⚡',
            text: 'Quema de grasa activa. Un par de horas más y alcanzas la meta.',
          ),
          _TimelineData(
            hour: 'Hora 14',
            icon: '✓',
            text: 'Meta alcanzada. Base sólida para el siguiente paso.',
          ),
        ];
      case '18:6':
        return [
          _TimelineData(
            hour: 'Hora 0',
            icon: '🔒',
            text: 'Cierras la ventana. El proceso empieza.',
          ),
          _TimelineData(
            hour: 'Hora 10',
            icon: '🔥',
            text: 'Insulina en mínimo. Quema de grasa en su punto máximo.',
            citation: '· Cahill, 1966 — NEJM',
          ),
          _TimelineData(
            hour: 'Hora 16',
            icon: '🧬',
            text: 'Autofagia activa: el cuerpo limpia células dañadas.',
            citation: '· Ohsumi, 2016 — Nobel de Medicina',
          ),
          _TimelineData(
            hour: 'Hora 18',
            icon: '💪',
            text: 'Meta. Cetosis metabólica leve en usuarios con práctica regular.',
          ),
        ];
      case '16:8':
      default:
        return [
          _TimelineData(
            hour: 'Hora 0',
            icon: '🔒',
            text: 'Cierras la ventana. Tu cuerpo empieza a usar glucosa almacenada.',
          ),
          _TimelineData(
            hour: 'Hora 8',
            icon: '🔥',
            text: 'La insulina baja. El cuerpo cambia de glucosa a grasa como combustible.',
            citation: '· Cahill, 1966 — NEJM',
          ),
          _TimelineData(
            hour: 'Hora 12',
            icon: '⚡',
            text: 'Quema de grasa activa. Tu energía viene de tus reservas.',
          ),
          _TimelineData(
            hour: 'Hora 16',
            icon: '🧬',
            text: 'Autofagia: limpieza celular profunda.',
            citation: '· Ohsumi, 2016 — Nobel de Medicina',
          ),
        ];
    }
  }
}

// ── PASO 104 — Notificaciones + Prueba social ────────────────────────
// Principios: Prueba social + Reciprocidad
// El dato 78/31% es estimado conservador (beta). Se reemplaza con datos
// reales de Firestore cuando el volumen lo permita.

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
          'Las personas que activan las notificaciones\ncompletan el doble de días',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 20),
        // Tarjeta de prueba social
        _SocialProofCard(isDark: isDark),
        const SizedBox(height: 20),
        Text(
          'Así se ven algunas notificaciones:',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _ExamplePill(
          icon: Icons.auto_awesome_outlined,
          headline: 'Llevas 12 horas — cambio de combustible',
          body: 'Tu cuerpo acaba de pasar de glucosa a grasa como '
              'fuente de energía.',
          citation: '· Cahill, 1966',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _ExamplePill(
          icon: Icons.nights_stay_outlined,
          headline: 'Tu ventana se cierra en 1 hora',
          body: 'Cenar después impacta tu sueño y tu score de mañana. '
              'Tu cuerpo agradece el cierre temprano.',
          citation: '· Spiegel, 2009 — JCEM',
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
              'Activar notificaciones',
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
              'Ahora no',
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

// ═══════════════════════════════════════════════════════════════════════
// Widgets de apoyo
// ═══════════════════════════════════════════════════════════════════════

/// Pill de cita bibliográfica. Usado en IntroWelcomeStep.
class _CitationPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _CitationPill({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.metabolicGreen;
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.bgSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de protocolo seleccionable. Usada en IntroProtocolStep.
class _ProtocolCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final bool isSelected;
  final bool recommended;
  final VoidCallback onTap;
  final bool isDark;

  const _ProtocolCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.metabolicGreen;
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF475569);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected
            ? accent.withValues(alpha: isDark ? 0.12 : 0.08)
            : (isDark ? AppColors.bgSurface : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? accent : (isDark ? AppColors.borderDefault : const Color(0xFFE2E8F0)),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Popular',
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? Icon(Icons.check_circle_rounded,
                        key: const ValueKey('checked'),
                        color: accent,
                        size: 26)
                    : Icon(Icons.radio_button_unchecked,
                        key: const ValueKey('unchecked'),
                        color: textSecondary.withValues(alpha: 0.4),
                        size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de timeline. Usada en IntroInsightStep.
class _TimelineRow extends StatelessWidget {
  final String hour;
  final String icon;
  final String text;
  final String? citation;
  final bool isDark;
  final bool isLast;

  const _TimelineRow({
    required this.hour,
    required this.icon,
    required this.text,
    required this.isDark,
    this.citation,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.metabolicGreen;
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF475569);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda: línea vertical + hora
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  hour,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.only(top: 4),
                      color: accent.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          // Icono
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          // Texto + cita
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (citation != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      citation!,
                      style: TextStyle(
                        color: textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de prueba social 78/31%. Usada en IntroNotificationsStep.
/// Datos: estimado conservador (beta). Reemplazar con datos reales de
/// Firestore cuando el volumen lo permita.
class _SocialProofCard extends StatelessWidget {
  final bool isDark;
  const _SocialProofCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.metabolicGreen;
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatColumn(
            value: '78%',
            label: 'Con\nnotificaciones',
            valueColor: accent,
            labelColor: textSecondary,
          ),
          Container(width: 1, height: 48, color: textSecondary.withValues(alpha: 0.2)),
          _StatColumn(
            value: '31%',
            label: 'Sin\nnotificaciones',
            valueColor: textPrimary,
            labelColor: textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final Color labelColor;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// Pill de notificación de ejemplo. Usada en IntroNotificationsStep.
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
        color: isDark ? AppColors.bgSurface : Colors.white,
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

/// Modelo de datos para una fila del timeline del insight.
class _TimelineData {
  final String hour;
  final String icon;
  final String text;
  final String? citation;

  const _TimelineData({
    required this.hour,
    required this.icon,
    required this.text,
    this.citation,
  });
}
