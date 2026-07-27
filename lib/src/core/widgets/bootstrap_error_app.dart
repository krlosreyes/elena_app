// Auditoría 2026-07-27 — hallazgo C-04.
//
// `main()` envolvía `_bootstrap()` en `runZonedGuarded`, pero si el
// bootstrap lanzaba ANTES de llegar a `runApp()` el handler de zona
// registraba el error en Crashlytics y terminaba. `runApp()` nunca se
// llamaba y el usuario veía una pantalla negra indefinida: sin mensaje,
// sin botón de reintentar y sin forma de saber qué pasó.
//
// El riesgo no era teórico. Siete operaciones pueden lanzar antes de
// `runApp`: `initializeDateFormatting`, `Firebase.initializeApp` (un
// GoogleService-Info.plist corrupto tras una actualización basta), las
// tres inicializaciones del primer `Future.wait`, `SharedPreferences`,
// `NotificationService.init` y `RevenueCatBillingService.initialize()`
// —esta última, una llamada de red en el camino crítico del primer frame.
//
// Este widget convierte un abandono silencioso en un incidente
// recuperable. Es deliberadamente autónomo: no depende de Riverpod, del
// tema de la app, de ScreenUtil ni de ningún servicio, porque cualquiera
// de ellos podría ser justamente lo que falló.

import 'package:flutter/material.dart';

/// Pantalla mínima que se muestra cuando el arranque de la app falla.
///
/// [onRetry] reintenta el bootstrap completo. Si vuelve a fallar, esta
/// misma pantalla se vuelve a montar con el nuevo error.
class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({
    super.key,
    required this.onRetry,
    this.technicalDetail,
  });

  final Future<void> Function() onRetry;

  /// Texto técnico del error. Se muestra colapsado y en pequeño: no le
  /// sirve al usuario, pero le sirve a soporte cuando manda una captura.
  final String? technicalDetail;

  static const _fondo = Color(0xFF0F172A);
  static const _superficie = Color(0xFF1E293B);
  static const _verde = Color(0xFF10B981);
  static const _texto = Color(0xFFE2E8F0);
  static const _tenue = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elena',
      home: Scaffold(
        backgroundColor: _fondo,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: _verde,
                    semanticLabel: 'Sin conexión con el servidor',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No pudimos abrir Elena',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _texto,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Algo falló al preparar la app. Suele ser la conexión: '
                    'revisa tu internet y vuelve a intentarlo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _tenue, fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 32),
                  _BotonReintentar(onRetry: onRetry),
                  if (technicalDetail != null) ...[
                    const SizedBox(height: 28),
                    Theme(
                      data: ThemeData.dark().copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Detalle técnico',
                          style: TextStyle(color: _tenue, fontSize: 13),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _superficie,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              technicalDetail!,
                              style: const TextStyle(
                                color: _tenue,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Si vuelve a pasar, escríbenos y te ayudamos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _tenue, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón con estado propio para que el reintento muestre progreso sin
/// obligar al widget padre a ser stateful.
class _BotonReintentar extends StatefulWidget {
  const _BotonReintentar({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<_BotonReintentar> createState() => _BotonReintentarState();
}

class _BotonReintentarState extends State<_BotonReintentar> {
  bool _reintentando = false;

  Future<void> _pulsar() async {
    if (_reintentando) return;
    setState(() => _reintentando = true);
    try {
      await widget.onRetry();
    } catch (_) {
      // Deliberado y sin re-lanzar: esta es la ÚLTIMA pantalla que le queda
      // al usuario. Si el reintento falla, lo correcto es volver a ofrecerle
      // el botón, no tumbar el único árbol de widgets que hay montado —
      // que es exactamente el fallo que esta pantalla existe para evitar.
      //
      // El error no se pierde: el `onRetry` real (`_bootstrapProtegido`) ya
      // lo registra en Crashlytics antes de volver a montar esta pantalla
      // con el detalle técnico actualizado.
    } finally {
      // Si el reintento tuvo éxito, `runApp` ya reemplazó este árbol y el
      // widget está desmontado; el guard evita el setState fantasma.
      if (mounted) setState(() => _reintentando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _reintentando ? null : _pulsar,
        style: ElevatedButton.styleFrom(
          backgroundColor: BootstrapErrorApp._verde,
          foregroundColor: BootstrapErrorApp._fondo,
          disabledBackgroundColor:
              BootstrapErrorApp._verde.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _reintentando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BootstrapErrorApp._fondo,
                ),
              )
            : const Text(
                'REINTENTAR',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
      ),
    );
  }
}
