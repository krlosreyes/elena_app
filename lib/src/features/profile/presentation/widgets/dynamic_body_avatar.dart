import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../shared/domain/models/user_model.dart';
import '../../../fasting/application/fasting_controller.dart';

class DynamicBodyAvatar extends ConsumerStatefulWidget {
  final UserModel user;
  final double? height;
  const DynamicBodyAvatar({super.key, required this.user, this.height});

  @override
  ConsumerState<DynamicBodyAvatar> createState() => _DynamicBodyAvatarState();
}

class _DynamicBodyAvatarState extends ConsumerState<DynamicBodyAvatar> {
  static const Color accentNeon = Color(0xFFFF9D00);
  static const Color neonRed = Color(0xFFFF2D55);
  static const Color neonYellow = Color(0xFFFFEA00);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonBlue = Color(0xFF00D2FF); // New Blueprint Blue
  static const Color safeNeon = Color(0xFF00E5FF);

  String? _activeHotspot;

  @override
  Widget build(BuildContext context) {
    final isFemale = widget.user.gender == Gender.female;
    final String svgAsset =
        isFemale ? 'assets/images/mujer.svg' : 'assets/images/hombre.svg';

    final double availableHeight =
        widget.height ?? MediaQuery.of(context).size.height;
    // REESCALADO: 35% de incremento para dominio visual
    final double avatarHeight = availableHeight * 1.35; 

    // 🧠 METRICS CALCULATION
    final double waist = widget.user.waistCircumferenceCm ?? 80.0;
    final double hips = widget.user.hipCircumferenceCm ?? 100.0;
    final double icc = waist / hips;
    final bool isAtRisk =
        isFemale ? (icc > 0.85) : (icc > 0.90); // 🚨 Biological Threshold

    final fastingState = ref.watch(fastingControllerProvider).valueOrNull;

    return GestureDetector(
      onLongPress: () => _showMissionBrief(context, fastingState),
      onTap: () => setState(() => _activeHotspot = null),
      child: Center(
        child: SizedBox(
          height: availableHeight,
          width: 320, 
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. AURA DE RIESGO (Abdominal Glow Condicional)
              if (isAtRisk)
                Positioned(
                  top: avatarHeight * 0.42, // Adjusted for new scale
                  child: Container(
                    width: 140,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: neonRed.withValues(alpha: 0.25),
                          blurRadius: 60,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. SILUETA BASE (Azul Neón Mate Opacidad 0.25)
              SvgPicture.asset(
                svgAsset,
                height: avatarHeight,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  neonBlue.withValues(alpha: 0.25), // Blueprint Look
                  BlendMode.srcIn,
                ),
              ),

              // 3. RADAR METABÓLICO (Esquina superior izquierda)
              Positioned(
                top: 20,
                left: 20,
                child: _buildMetabolicRadar(),
              ),

              // 4. HOTSPOTS INTERACTIVOS (Lógica Semáforo)
              _buildHotspot(
                id: 'neck',
                label: 'CUELLO',
                value: widget.user.neckCircumferenceCm ?? 38.0,
                top: 0.16,
                left: 0.52,
                delta: 0.0,
                color: neonYellow, // Mantenimiento
              ),
              _buildHotspot(
                id: 'arm',
                label: 'BRAZO',
                value: 32.5, 
                top: 0.32,
                left: 0.22,
                delta: -0.5, 
                color: neonGreen, // Objetivo Logrado
              ),
              _buildHotspot(
                id: 'waist',
                label: 'CINTURA',
                value: waist,
                top: 0.46,
                left: 0.55,
                delta: -1.0,
                // ROJO si hay riesgo crítico (ICC alto), AMARILLO si estable, VERDE si ideal
                color: isAtRisk ? neonRed : (waist < 80 ? neonGreen : neonYellow),
              ),
              _buildHotspot(
                id: 'hip',
                label: 'CADERA',
                value: hips,
                top: 0.58,
                left: 0.53,
                delta: -0.5,
                color: neonYellow, 
              ),
              _buildHotspot(
                id: 'thigh',
                label: 'MUSLO',
                value: 58.0, 
                top: 0.72,
                left: 0.38,
                delta: -1.2,
                color: neonGreen, 
              ),

              // 5. BARRA DE METAMORFOSIS (Avance de Peso)
              Positioned(
                bottom: 10,
                left: 40,
                right: 40,
                child: _MetamorphosisBar(user: widget.user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Radar Metabólico (% Grasa)
  Widget _buildMetabolicRadar() {
    final currentFat = widget.user.currentFatPercentage ?? 25.0;
    final targetFat = widget.user.targetFatPercentage ?? 15.0;
    // Progress towards goal
    double progress = ((40.0 - currentFat) / (40.0 - targetFat)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RADAR METABÓLICO',
          style: GoogleFonts.jetBrainsMono(
            color: neonBlue.withValues(alpha: 0.6),
            fontSize: 7,
            letterSpacing: 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(neonBlue.withValues(alpha: 0.1)),
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(accentNeon),
                backgroundColor: Colors.transparent,
              ),
              Center(
                child: Text(
                  '${currentFat.toStringAsFixed(0)}%',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotspot({
    required String id,
    required String label,
    required double value,
    required double top,
    required double left,
    required Color color,
    double delta = 0.0,
  }) {
    final bool isActive = _activeHotspot == id;

    return Positioned(
      top: (widget.height ?? 600) * top,
      left: 320 * left,
      child: GestureDetector(
        onTap: () => setState(() => _activeHotspot = id),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // El Punto (Hotspot) Neón
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2)
                ],
              ),
            ),

            // Tooltip Reactivo Naranja Neón
            if (isActive)
              Positioned(
                top: -45,
                left: -60,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accentNeon.withValues(alpha: 0.5)),
                    boxShadow: [
                       BoxShadow(color: accentNeon.withValues(alpha: 0.2), blurRadius: 10)
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.jetBrainsMono(
                          color: accentNeon.withValues(alpha: 0.8),
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${value.toStringAsFixed(1)}cm (Δ ${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)})',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMissionBrief(BuildContext context, dynamic fastingState) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22), // Technical Gray/Blue
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BRIEF DE MISIÓN METABÓLICA',
                style: GoogleFonts.jetBrainsMono(
                  color: safeNeon,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Divider(color: Colors.white12, height: 24),
              _buildBriefRow(
                'ESTADO ACTUAL',
                fastingState?.isFasting == true
                    ? 'Fase Catabólica (Autofagia)'
                    : 'Fase Anabólica (Nutrición)',
              ),
              const SizedBox(height: 12),
              _buildBriefRow(
                'RECOMENDACIÓN',
                fastingState?.isFasting == true
                    ? 'Tu sensibilidad a la insulina es óptima. Elena sugiere Movilidad (Zona 2) para maximizar la autofagia.'
                    : 'Asegura un aporte proteico de 30g+ para estabilizar el estímulo de mTOR y saciedad.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  child: Text(
                    'ENTENDIDO',
                    style: GoogleFonts.jetBrainsMono(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBriefRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white24,
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.publicSans(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}

class _MetamorphosisBar extends StatelessWidget {
  final UserModel user;
  const _MetamorphosisBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final start = user.startWeightKg ?? 90.0;
    final current = user.currentWeightKg;
    final goal = user.targetWeightKg ?? 75.0;

    // Calcular progreso 0.0 a 1.0 (invertido si se quiere perder peso)
    double progress = 0.5;
    if ((start - goal).abs() > 0.1) {
      progress = (start - current) / (start - goal);
    }
    progress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('INICIO: ${start.toStringAsFixed(0)}KG',
                style: GoogleFonts.jetBrainsMono(
                    color: Colors.white24, fontSize: 8)),
            Text('META: ${goal.toStringAsFixed(0)}KG',
                style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFFFF9D00), fontSize: 8)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // La barra de progreso neón
            Container(
              height: 4,
              width: progress * 240, // Aproximado
              decoration: BoxDecoration(
                color: const Color(0xFFFF9D00),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFFF9D00).withValues(alpha: 0.4),
                      blurRadius: 6)
                ],
              ),
            ),
            // El círculo naranja (posición actual)
            Positioned(
              left: (progress * 240) - 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9D00),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
