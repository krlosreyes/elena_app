// SPEC-247 (2026-07-07): Onboarding por Transformación.
// Rediseño completo de las pantallas educativas con principios de influencia
// anclados a la identidad científica de ElenaApp (ver ENGAGEMENT_ANALYSIS_2026_07.md).
//
// Pantallas activas:
//   100 — IntroWelcomeStep    (Identidad: Unidad + Autoridad)
//   105 — IntroProtocolStep   (Compromiso y coherencia) ← NUEVA
//   101 — IntroInsightStep    (Reciprocidad + Autoridad) ← sustituye IntroImrStep
//   103 — IntroMetabolicDayStep (qué es tu día metabólico) ← RESTAURADA 28-jul
//   104 — IntroNotificationsStep (por qué avisar + activar) ← rediseñada
//
// Pantallas eliminadas:
//   102 — IntroDataStep       → privacidad absorbida en header de Biometría (onboarding_screen)
//
// Sobre la 103 (28-jul-2026): se había retirado con la nota "movida a
// coaching card post-Day-1 (SPEC-249, deferred)". Ese spec nunca existió
// —no hay archivo en specs/ ni una sola referencia en lib/ más allá de
// las dos notas que lo prometían— así que la explicación se quitó y el
// reemplazo no llegó nunca. Mientras tanto "Día Metabólico" siguió
// apareciendo en 10 pantallas en mayúsculas, como si el usuario ya
// supiera qué es.
//
// Vuelve, pero con el texto viniendo de `metabolic_day_copy.dart` en vez
// de escrito aquí: ahora la misma definición sirve al onboarding y a la
// hoja explicativa, y los cierres automáticos se derivan de las
// constantes del resolver.
//
// Reglas de copy:
//   - Español neutro LatAm. CERO voseo (no vos/acá/tenés/empezás/cumplís).
//   - Solo iconos Material. Sin assets ni dependencias externas.
//   - Cada claim científico lleva su cita.

import 'package:flutter/material.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
// Fuente única de los umbrales de fase. El onboarding NO define los suyos:
// ver la nota en `IntroInsightStep._timelineFor`.
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart'
    show FastingPhase;
// Fuente única del copy del Día Metabólico — compartida con la hoja
// explicativa. Ver la nota de cabecera sobre el paso 103.
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_day_copy.dart';

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
          // 27-jul-2026: decía "El 70% de las personas empieza aquí". Es
          // la misma cifra sin fuente que el 78/31% de la pantalla de
          // notificaciones, y ElenaApp tampoco tiene datos para
          // sostenerla. Lo que sí es cierto y verificable es que 16:8 es
          // el protocolo con más literatura detrás.
          description: 'El más estudiado. El punto de partida habitual.',
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
              color: isDark ? AppColors.borderDefault : const Color(0xFFE2E8F0),
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

  /// Pie de la pantalla.
  ///
  /// La segunda frase dice explícitamente dónde empieza la autofagia y
  /// que este protocolo no llega. Es información que la versión anterior
  /// no solo omitía: la contradecía, anunciando autofagia a las 16 h. Un
  /// usuario que lee esto y luego ve "24 h autofagia" en la leyenda del
  /// reloj encuentra el mismo número — que es justo lo que la app promete
  /// en su primera pantalla.
  static String _footerFor(String protocol) {
    final horas = _horasDe(protocol);
    final autofagia = FastingPhase.autophagy.startsAt.inHours;

    final notaAutofagia = horas < autofagia
        ? 'La autofagia empieza alrededor de las $autofagia h: tu protocolo '
            'no llega ahí, y no hace falta para lo que buscas. '
        : '';

    switch (protocol) {
      case '14:10':
        return 'Estos eventos son automáticos. $notaAutofagia'
            '14/10 es el protocolo ideal para construir el hábito. '
            'ElenaApp te avisa en cada hito.';
      case '18:6':
        return 'Estos eventos son automáticos. $notaAutofagia'
            '18/6 requiere que tu sistema digestivo esté adaptado. '
            'ElenaApp ajusta el coaching si el patrón necesita cambio.';
      case '16:8':
      default:
        return 'Estos eventos son automáticos. $notaAutofagia'
            'Tu trabajo es darle el tiempo necesario. '
            'ElenaApp te avisa en cada hito.';
    }
  }

  /// Horas de ayuno del protocolo. '16:8' → 16.
  static int _horasDe(String protocol) =>
      int.tryParse(protocol.split(RegExp(r'[:/]')).first) ?? 16;

  /// Línea de tiempo del ayuno, DERIVADA de `FastingPhase`.
  ///
  /// POR QUÉ SE REESCRIBIÓ (recorrido en Simulador, 27-jul-2026)
  /// -----------------------------------------------------------
  /// Antes eran tres tablas de umbrales escritos a mano, una por
  /// protocolo, y no coincidían ni con el motor ni entre sí:
  ///
  ///     evento           14:10   16:8   18:6   enum canónico
  ///     insulina baja      h6      h8    h10   h0
  ///     quema de grasa    h12     h12    h10   h18
  ///     autofagia          —      h16    h16   h24
  ///
  /// La biología no sabe qué protocolo eligió el usuario. Que el umbral
  /// se moviera con la elección delata que los números se ajustaron para
  /// que cada protocolo "llegara" a un hito: diseño motivacional, no
  /// fisiología. Y encima iba firmado — Ohsumi bajo "autofagia a las
  /// 16 h" (su Nobel fue por el mecanismo en levaduras, no por un umbral
  /// humano) y Cahill citado tres veces para el mismo fenómeno en tres
  /// horas distintas. Todo ello en el flujo que abre diciendo "No te
  /// pedimos fe — te damos las fuentes".
  ///
  /// Ahora las filas salen de `FastingPhase.startsAt`, así que mover un
  /// umbral se propaga solo. La consecuencia incómoda —y correcta— es
  /// que ningún protocolo de la app llega a la autofagia: empieza a las
  /// 24 h y el más largo es de 18. El pie de pantalla lo dice en vez de
  /// esconderlo. Prometer autofagia diaria a un usuario de 16:8 era una
  /// promesa que el Dashboard le iba a desmentir cada día.
  ///
  /// Lo vigila `check_in_copy_coherence_test.dart`.
  static List<_TimelineData> _timelineFor(String protocol) {
    final horas = _horasDe(protocol);
    final meta = Duration(hours: horas);

    final filas = <_TimelineData>[
      const _TimelineData(
        hour: 'Hora 0',
        icon: '🔒',
        text: 'Cierras la ventana. Tu cuerpo usa la energía de lo que comiste.',
      ),
      // `postAbsorption` arranca en 0 y dura hasta las 12 h: es un tramo,
      // no un instante. Ponerle una hora concreta fue justo el origen del
      // problema (h6/h8/h10 según el protocolo), así que se nombra como
      // lo que es.
      const _TimelineData(
        hour: 'Primeras horas',
        icon: '🔥',
        text: 'La insulina baja y tu cuerpo empieza a tirar de reservas.',
        citation: '· Cahill, 1966 — NEJM',
      ),
    ];

    for (final fase in FastingPhase.values) {
      if (fase == FastingPhase.none || fase == FastingPhase.postAbsorption) {
        continue;
      }
      // No se alcanza dentro del protocolo: no se anuncia.
      if (fase.startsAt >= meta) break;
      filas.add(_TimelineData(
        hour: 'Hora ${fase.startsAt.inHours}',
        icon: fase == FastingPhase.transition ? '⚡' : '💪',
        text: '${fase.milestoneName}. ${fase.description}',
      ));
    }

    // Si la meta coincide con el umbral de una fase, se nombran juntas.
    FastingPhase? faseEnMeta;
    for (final fase in FastingPhase.values) {
      if (fase != FastingPhase.none && fase.startsAt == meta) {
        faseEnMeta = fase;
        break;
      }
    }
    filas.add(_TimelineData(
      hour: 'Hora $horas',
      icon: '✓',
      text: faseEnMeta == null
          ? 'Meta alcanzada.'
          : 'Meta alcanzada. Entras en '
              '${faseEnMeta.milestoneName.toLowerCase()}.',
    ));

    return filas;
  }
}

// ── PASO 104 — Notificaciones ────────────────────────────────────────
//
// POR QUÉ YA NO HAY "PRUEBA SOCIAL" AQUÍ (recorrido, 27-jul-2026)
// ----------------------------------------------------------------
// Esta pantalla mostraba "78% con notificaciones / 31% sin
// notificaciones" bajo el titular "completan el doble de días". Tres
// problemas, y el tercero es el grave:
//
//   1. 78 contra 31 no es "el doble", es 2,5 veces.
//   2. Era el ÚNICO dato numérico de todo el onboarding sin cita, en un
//      flujo donde cada afirmación fisiológica lleva su paper — y el
//      único que servía al interés de la app en vez del entendimiento
//      del usuario.
//   3. El comentario que había aquí lo admitía: "estimado conservador
//      (beta)". Es decir, inventado. Un comentario en el código no es
//      una divulgación al usuario, y con ~10 testers es aritméticamente
//      imposible tener ese dato.
//
// Es exactamente la categoría de afirmación por la que la FTC multó a
// Noom con 56M USD: prueba social cuantificada, sin respaldo, justo
// antes de una decisión que beneficia al producto.
//
// La sustituye una afirmación verdadera, que apoya la misma decisión sin
// inventar nada: sin avisos, la app depende de que el usuario se acuerde.
// Si algún día hay volumen real para medir la diferencia, se puede
// volver a poner un número — CON su fuente y su fecha.

// ── PASO 103 — Qué es tu Día Metabólico ──────────────────────────────
//
// Va DESPUÉS de elegir protocolo (105) y del insight (101), y antes de
// notificaciones (104). El orden importa: la definición habla de "tu
// ayuno", así que solo tiene sentido cuando el usuario ya eligió uno.
//
// Todo el texto viene de `metabolic_day_copy.dart`. Este paso solo lo
// pinta — la misma definición se muestra luego en la hoja explicativa
// accesible desde el Dashboard, y dos redacciones distintas de la misma
// regla es como empiezan las incoherencias.

class IntroMetabolicDayStep extends StatelessWidget {
  final bool isDark;

  /// Protocolo elegido en el paso 105. Decide si se muestra la nota del
  /// modo calendárico — con 'Ninguno' el ciclo SÍ va con el reloj y
  /// cierra a medianoche, que es lo contrario de lo que dice la
  /// definición principal. Callarlo dejaría a esa persona sin entender
  /// lo que ve.
  final String protocol;

  const IntroMetabolicDayStep({
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
    final esCalendario = usaDiaCalendario(protocol);

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
              Icons.autorenew_rounded,
              color: AppColors.metabolicGreen,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Tu día no empieza a medianoche',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.metabolicGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.metabolicGreen.withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            kMetabolicDayCoreDefinition,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          kMetabolicDayRationale,
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
        _MetabolicDayRow(
          icon: Icons.play_circle_outline_rounded,
          title: kMetabolicDayStartTitle,
          body: kMetabolicDayStartBody,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 10),
        _MetabolicDayRow(
          icon: Icons.flag_outlined,
          title: kMetabolicDayEndTitle,
          body: kMetabolicDayEndBody,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 10),
        _MetabolicDayRow(
          icon: Icons.shield_outlined,
          title: kMetabolicDayAutoCloseTitle,
          body: kMetabolicDayAutoCloseBody,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        if (esCalendario) ...[
          const SizedBox(height: 10),
          _MetabolicDayRow(
            icon: Icons.calendar_today_rounded,
            title: kMetabolicDayCalendarTitle,
            body: kMetabolicDayCalendarBody,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ],
    );
  }
}

class _MetabolicDayRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color textPrimary;
  final Color textSecondary;

  const _MetabolicDayRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.metabolicGreen, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.5,
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
          'Elena mira el reloj\npara que tú no tengas que hacerlo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 20),
        _PorQueAvisarCard(isDark: isDark),
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
        color: isDark ? AppColors.bgSurface : Colors.white,
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
          color: isSelected
              ? accent
              : (isDark ? AppColors.borderDefault : const Color(0xFFE2E8F0)),
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
                        key: const ValueKey('checked'), color: accent, size: 26)
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

/// Sustituye a la antigua tarjeta de "prueba social" con el 78/31%
/// inventado. Ver la nota larga en la cabecera de `IntroNotificationsStep`.
///
/// Todo lo que afirma es comprobable en el código: los avisos de fase los
/// programa `NotificationScheduler.scheduleCheckInMilestones` y el del
/// cierre de ventana sale de `EatingWindowState`.
class _PorQueAvisarCard extends StatelessWidget {
  final bool isDark;
  const _PorQueAvisarCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.metabolicGreen;
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvisoRow(
            icon: Icons.schedule_rounded,
            text: 'Cuando tu cuerpo cambia de fase',
            accent: accent,
            textColor: textPrimary,
          ),
          const SizedBox(height: 12),
          _AvisoRow(
            icon: Icons.dinner_dining_outlined,
            text: 'Cuando se acerca el cierre de tu ventana',
            accent: accent,
            textColor: textPrimary,
          ),
          const SizedBox(height: 14),
          Text(
            'Sin avisos, la app solo funciona si te acuerdas de abrirla.',
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;
  final Color textColor;

  const _AvisoRow({
    required this.icon,
    required this.text,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// `_StatColumn` vivía aquí: era la columna de número grande que pintaba
// el "78%" y el "31%". Se retira con la tarjeta de prueba social — no
// quedan cifras de adherencia que mostrar hasta que existan de verdad.

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
