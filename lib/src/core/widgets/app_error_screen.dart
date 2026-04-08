import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Pantalla genérica de error reutilizable para providers con estado error.
///
/// Fondo oscuro, icono de alerta neón rojo, mensaje en español
/// y botón REINTENTAR que ejecuta [onRetry].
class AppErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorScreen({
    super.key,
    this.message = 'Algo salió mal. Intenta de nuevo.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020205),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icono de alerta ──
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 36,
                ),
              ),

              const SizedBox(height: 24),

              // ── Título ──
              Text(
                'ERROR DEL SISTEMA',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 12),

              // ── Mensaje ──
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // ── Botón REINTENTAR ──
              if (onRetry != null)
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.6),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'REINTENTAR',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
