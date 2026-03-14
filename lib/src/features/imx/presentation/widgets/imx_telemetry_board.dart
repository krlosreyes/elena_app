import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/imx_provider.dart';
import '../../domain/imx_engine.dart';

class ImxTelemetryBoard extends ConsumerWidget {
  const ImxTelemetryBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imxAsync = ref.watch(currentImxResultProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D1B2A), // Deep dark premium blue
            Color(0xFF111111),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF009688).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009688).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFB2).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Color(0xFF00FFB2), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'TELEMETRÍA IMX',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.firaCode(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          imxAsync.when(
            data: (result) => _ImxDataDisplay(result: result),
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error de Red/Sistema: $err',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImxPendingState extends StatelessWidget {
  const _ImxPendingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            'Índice Metamorfosis (IMX) Pendiente',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tus medidas corporales (cuello, cintura) en tu perfil para desbloquear este análisis avanzado en tiempo real.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          /*
          // Podríamos agregar un botón de acceso directo aquí en el futuro
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
               // TODO: Navigate to Profile/Edit Measurements
            },
            icon: const Icon(Icons.straighten, size: 18),
            label: const Text('Completar Perfil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FFB2),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          */
        ],
      ),
    );
  }
}

class _ImxDataDisplay extends StatelessWidget {
  final ImxResult result;
  const _ImxDataDisplay({required this.result});

  @override
  Widget build(BuildContext context) {
    final imx = result.total;
    final levelText = result.category;
    final levelColor = switch (result.categoryType) {
      'deteriorated' => Colors.redAccent,
      'unstable' => Colors.orange,
      'functional' => Colors.cyanAccent,
      'efficient' => const Color(0xFF00FFB2),
      'optimized' => const Color(0xFF00FFB2),
      _ => Colors.grey,
    };

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Inner Glow for recalculation effect
                TweenAnimationBuilder<double>(
                  key: ValueKey(imx), // Triggers when score changes
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, flashValue, _) {
                    final opacity = (1.0 - flashValue).clamp(0.0, 1.0);
                    return Container(
                      width: 140 + (20 * flashValue),
                      height: 140 + (20 * flashValue),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withOpacity(0.3 * opacity),
                            blurRadius: 40 * opacity,
                            spreadRadius: 10 * opacity,
                          ),
                        ],
                        border: Border.all(
                          color: levelColor.withOpacity(0.5 * opacity),
                          width: 2,
                        ),
                      ),
                    );
                  }
                ),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: imx / 100.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: value,
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (value * 100).toStringAsFixed(0),
                                  style: GoogleFonts.firaCode(
                                    color: Colors.white, 
                                    fontSize: 42, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.trending_up, color: Colors.greenAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+1.2 PTS HOY',
                                      style: GoogleFonts.firaCode(
                                        color: Colors.greenAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Text(
                levelText.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: levelColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'METABOLISMO ${result.categoryType == "optimized" || result.categoryType == "efficient" ? "ACTIVO" : "EN OPTIMIZACIÓN"}',
                style: GoogleFonts.firaCode(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PillarChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _PillarChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.robotoMono(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.toStringAsFixed(0),
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

