// SPEC-98: bottom sheet educativo para seleccionar protocolo de
// ayuno. Reemplaza el grid 2×4 que vivía en el Perfil y lo trae al
// Dashboard donde el usuario realmente lo necesita (junto al
// cronómetro de ayuno).
//
// Patrón: Material 3 Modal Bottom Sheet con lista vertical de items
// educativos. Cada item lleva: nombre, nivel (chip de color),
// descripción 1-2 líneas con justificación científica.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

/// Metadata estática por protocolo. Nivel de dificultad + descripción
/// usada en el sheet. Las descripciones citan el marco bibliográfico
/// (CIRCADIAN_BIBLIOGRAPHY §2 — fases del ayuno).
class _ProtocolInfo {
  final String code;
  final String level;
  final Color levelColor;
  final String description;

  const _ProtocolInfo({
    required this.code,
    required this.level,
    required this.levelColor,
    required this.description,
  });
}

const List<_ProtocolInfo> _kProtocols = [
  _ProtocolInfo(
    code: 'Ninguno',
    level: 'Educativo',
    levelColor: Color(0xFF94A3B8),
    description:
        'Sin ventana de ayuno estricta. Para construir hábitos básicos antes '
        'de entrar al TRF.',
  ),
  _ProtocolInfo(
    code: '12:12',
    level: 'Principiante',
    levelColor: Color(0xFF60A5FA),
    description:
        'Ventana suave de 12h. Entrada cómoda al ayuno intermitente sin '
        'romper rutinas sociales.',
  ),
  _ProtocolInfo(
    code: '14:10',
    level: 'Principiante',
    levelColor: Color(0xFF60A5FA),
    description:
        'Ventana de 10h. Punto medio para principiantes con tolerancia '
        'metabólica básica.',
  ),
  _ProtocolInfo(
    code: '16:8',
    level: 'Intermedio',
    levelColor: AppColors.metabolicGreen,
    description:
        'Clásico. Promueve autofagia ligera y mejora sensibilidad a insulina '
        '(Mattson 2017).',
  ),
  _ProtocolInfo(
    code: '18:6',
    level: 'Intermedio',
    levelColor: AppColors.metabolicGreen,
    description:
        'Ayuno moderado-intenso. Aumenta autofagia y cetosis nutricional sin '
        'extremos.',
  ),
  _ProtocolInfo(
    code: '20:4',
    level: 'Avanzado',
    levelColor: Color(0xFFFB923C),
    description:
        'Ventana corta de 4h. Para usuarios con experiencia previa y rutina '
        'consolidada.',
  ),
  _ProtocolInfo(
    code: '22:2',
    level: 'Avanzado',
    levelColor: Color(0xFFFB923C),
    description:
        'Ayuno largo. Recomendado con supervisión clínica y tolerancia '
        'confirmada.',
  ),
  _ProtocolInfo(
    code: 'OMAD',
    level: 'Extremo',
    levelColor: Color(0xFFEF4444),
    description:
        'Una comida al día. Protocolo extremo — solo con supervisión médica '
        'activa.',
  ),
];

class ProtocolSelectorSheet extends StatelessWidget {
  final String currentProtocol;
  final String? recommendedProtocol;

  const ProtocolSelectorSheet({
    super.key,
    required this.currentProtocol,
    this.recommendedProtocol,
  });

  /// Helper estático: muestra el sheet y resuelve con el protocolo
  /// elegido (o null si el usuario canceló).
  static Future<String?> show(
    BuildContext context, {
    required String currentProtocol,
    String? recommendedProtocol,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ProtocolSelectorSheet(
          currentProtocol: currentProtocol,
          recommendedProtocol: recommendedProtocol,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle visual.
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
            const SizedBox(height: 16),
            const Text(
              'Elige tu protocolo de ayuno',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'El cierre canónico de ventana es 20:30 — antes del bloqueo '
              'intestinal a las 22:00.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _kProtocols.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final info = _kProtocols[i];
                  final isCurrent = info.code == currentProtocol;
                  final isRecommended = recommendedProtocol != null &&
                      info.code == recommendedProtocol &&
                      !isCurrent;
                  return _ProtocolItem(
                    info: info,
                    isCurrent: isCurrent,
                    isRecommended: isRecommended,
                    onTap: () => Navigator.of(ctx).pop(info.code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolItem extends StatelessWidget {
  final _ProtocolInfo info;
  final bool isCurrent;
  final bool isRecommended;
  final VoidCallback onTap;

  const _ProtocolItem({
    required this.info,
    required this.isCurrent,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? AppColors.metabolicGreen
                : Colors.white.withValues(alpha: 0.06),
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.metabolicGreen.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre + nivel
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: info.levelColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      info.level.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: info.levelColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Descripción + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isCurrent)
                        const _Badge(
                          label: 'ACTUAL',
                          color: AppColors.metabolicGreen,
                        ),
                      if (isRecommended)
                        const _Badge(
                          label: 'RECOMENDADO',
                          color: Color(0xFF60A5FA),
                        ),
                    ],
                  ),
                  if (isCurrent || isRecommended) const SizedBox(height: 6),
                  Text(
                    info.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.metabolicGreen,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}
