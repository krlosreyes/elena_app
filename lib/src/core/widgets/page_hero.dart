import 'package:flutter/material.dart';

/// Título de una pestaña raíz — fuente única (29-jul).
///
/// Antes cada pantalla escribía su propio título a mano y había dos
/// tratamientos distintos conviviendo:
///
///   Progreso  → texto en el cuerpo, 34 · w800 · tracking −0.5
///   Perfil    → AppBar, 18 · w700 · tracking 0
///   Dashboard → sin título
///   Detalle   → AppBar, 18 · w700 · tracking 0
///
/// El problema no era solo que no coincidieran de tamaño: Perfil, siendo
/// una pestaña raíz, se veía IDÉNTICO a sus propias pantallas hijas, así
/// que el título no te decía en qué nivel estabas.
///
/// La regla que queda: **hero grande = pestaña raíz, AppBar 18 = pantalla
/// abierta desde ahí.** Las de detalle no usan este widget a propósito;
/// siguen con su `AppBar`, que además trae el botón de volver.
class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;

  /// Línea secundaria bajo el título. Suele ser la fecha de hoy.
  /// `null` en Perfil, que no tiene nada que fechar.
  final String? subtitle;

  /// Elemento a la derecha, alineado con el título. Lo usa el Dashboard
  /// para el avatar que lleva al Perfil.
  final Widget? trailing;

  /// Tamaño del título. Público para que un test pueda afirmar que las
  /// tres pestañas comparten el mismo número en vez de comparar
  /// capturas de pantalla.
  static const double titleFontSize = 34;

  @override
  Widget build(BuildContext context) {
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    if (trailing == null) return textos;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // `Expanded` y no un ancho fijo: un título largo debe robarle
        // espacio al trailing, no desbordar la fila.
        Expanded(child: textos),
        const SizedBox(width: 12),
        trailing!,
      ],
    );
  }
}

/// Fecha de hoy en el formato que usan los heroes: "miércoles, 29 de julio".
///
/// Vivía como método privado dentro de `analysis_screen.dart`, con sus
/// propias listas de días y meses. Al llevar el hero al Dashboard habría
/// hecho falta una segunda copia — que es justo como empiezan estas
/// divergencias.
String heroTodayLabel([DateTime? now]) {
  final n = now ?? DateTime.now();
  final dia = _diasLargos[(n.weekday - 1).clamp(0, 6)];
  final mes = _mesesLargos[n.month - 1];
  return '$dia, ${n.day} de $mes';
}

const _diasLargos = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const _mesesLargos = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
