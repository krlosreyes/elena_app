// SPEC-16: Guía de Bienvenida
// Flujo de 5 slides que presenta la app al usuario recién onboardeado.
// Se muestra UNA sola vez. Al completar o saltar: marca la bandera y navega
// al dashboard. No expone jerga técnica ni fórmulas.
//
// Slides:
//   1. Bienvenida a Elena
//   2. El IMR — qué es y para qué sirve
//   3. Los 5 pilares del método
//   4. Cómo funciona el día a día
//   5. Todo listo — CTA para empezar

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/welcome/application/welcome_service.dart';
// SPEC-17: Vocabulario funcional de pilares
import 'package:elena_app/src/core/constants/pillar_constants.dart';

class WelcomeFlowScreen extends ConsumerStatefulWidget {
  const WelcomeFlowScreen({super.key});

  @override
  ConsumerState<WelcomeFlowScreen> createState() => _WelcomeFlowScreenState();
}

class _WelcomeFlowScreenState extends ConsumerState<WelcomeFlowScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  static const List<_SlideData> _slides = [
    _SlideData(
      emoji:       '🧬',
      title:       'Bienvenido a Elena',
      subtitle:    'Tu metabolismo tiene un idioma.',
      description: 'Elena lo traduce en acciones concretas, basadas en la misma '
                   'ciencia que usan los atletas de élite para optimizar su salud.',
      accentColor: Color(0xFF1ABC9C),
    ),
    _SlideData(
      emoji:       '📊',
      title:       'Tu IMR: el número que lo resume todo',
      subtitle:    'Indicador Metabólico Real — de 0 a 100.',
      description: 'Integra tu composición corporal, tu ayuno activo y tus hábitos '
                   'circadianos en un solo score objetivo. Sube cada vez que haces '
                   'bien las cosas. Baja cuando el cuerpo necesita atención.',
      accentColor: Color(0xFF3498DB),
      showImrBar:  true,
    ),
    _SlideData(
      emoji:       '🏛️',
      title:       'Un sistema de 5 pilares',
      subtitle:    'Cada pilar alimenta el siguiente.',
      description: '',    // overridden — se dibuja el grid de pilares
      accentColor: Color(0xFFF39C12),
      showPillars: true,
    ),
    _SlideData(
      emoji:       '🎯',
      title:       'Elena hace el trabajo pesado',
      subtitle:    'Tú registras. Ella calcula y recomienda.',
      description: 'Cada vez que marcas un pilar, Elena recalcula tu IMR en tiempo '
                   'real y ajusta sus sugerencias a tu biología específica — no a '
                   'promedios poblacionales.',
      accentColor: Color(0xFF9B59B6),
    ),
    _SlideData(
      emoji:       '🚀',
      title:       'Todo está configurado',
      subtitle:    'Tu perfil y protocolo están listos.',
      description: 'El primer paso es registrar tu ayuno de hoy. Tu IMR inicial '
                   'ya está calculado. Cada día de consistencia lo hace subir.',
      accentColor: Color(0xFF1ABC9C),
      isLast:      true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_isCompleting) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isCompleting = true);
    await WelcomeService.markWelcomeSeen(user.uid);
    if (mounted) context.go('/dashboard');
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final bool isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: isLast
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: _complete,
                        child: Text(
                          'Saltar',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.35),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),

            // ── Slides ────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _WelcomeSlide(data: _slides[i]),
              ),
            ),

            // ── Dots + CTA ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final bool active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width:  active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? slide.accentColor
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // CTA principal
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isCompleting ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: slide.accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: _isCompleting
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              isLast ? 'Comenzar ahora' : 'Siguiente',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Datos de cada slide ──────────────────────────────────────────────────────

class _SlideData {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color  accentColor;
  final bool   showImrBar;
  final bool   showPillars;
  final bool   isLast;

  const _SlideData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    this.showImrBar  = false,
    this.showPillars = false,
    this.isLast      = false,
  });
}

// ─── Widget de slide individual ───────────────────────────────────────────────

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji hero con halo de color
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              color: data.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: data.accentColor.withOpacity(0.25),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Título
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Subtítulo
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: data.accentColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Contenido variable
          if (data.showImrBar)
            _ImrZoneBar()
          else if (data.showPillars)
            _PillarGrid()
          else if (data.description.isNotEmpty)
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.55),
                height: 1.7,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Barra de zonas IMR (slide 2) ─────────────────────────────────────────────

class _ImrZoneBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const zones = [
      _ZoneItem('DETERIORADO', '0–39',  Color(0xFFC0392B)),
      _ZoneItem('INESTABLE',   '40–59', Color(0xFFE67E22)),
      _ZoneItem('FUNCIONAL',   '60–74', Color(0xFFF39C12)),
      _ZoneItem('EFICIENTE',   '75–89', Color(0xFF27AE60)),
      _ZoneItem('OPTIMIZADO',  '90–100',Color(0xFF1ABC9C)),
    ];

    return Column(
      children: [
        // Barra de gradiente
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: zones.map((z) => Expanded(
              child: Container(height: 10, color: z.color),
            )).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: zones.map((z) => Column(
            children: [
              Text(
                z.range,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: z.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                z.label,
                style: TextStyle(
                  fontSize: 7,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          )).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Cada acción en tus pilares mueve este número.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.5),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ZoneItem {
  final String label;
  final String range;
  final Color  color;
  const _ZoneItem(this.label, this.range, this.color);
}

// ─── Grid de 5 pilares (slide 3) ─────────────────────────────────────────────

class _PillarGrid extends StatelessWidget {
  // SPEC-17: nombres y descripciones usan el vocabulario funcional de PillarConstants
  static const _pillars = [
    _PillarItem('⏱️', PillarConstants.pilarAyuno,
        'Regula insulina\ny quema grasa',     Color(0xFF10B981)),
    _PillarItem('💪', PillarConstants.pilarEjercicio,
        'Preserva músculo\ny activa AMPK',    Color(0xFF2DD4BF)),
    _PillarItem('🥦', PillarConstants.pilarNutricion,
        'Índice insulínico\ny ventana circadiana', Color(0xFFFB923C)),
    _PillarItem('🌙', PillarConstants.pilarSoporte,
        'Regula hormonas\ny recuperación',    Color(0xFF818CF8)),
    _PillarItem('⚡', PillarConstants.pilarInsulina,
        'Timing de comidas\ny ritmo biológico', Color(0xFFF59E0B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primera fila: 3 pilares
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _pillars.take(3).map((p) => _PillarTile(data: p)).toList(),
        ),
        const SizedBox(height: 10),
        // Segunda fila: 2 pilares centrados
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _pillars.skip(3).map((p) => _PillarTile(data: p)).toList(),
        ),
      ],
    );
  }
}

class _PillarItem {
  final String emoji;
  final String name;
  final String detail;
  final Color  color;
  const _PillarItem(this.emoji, this.name, this.detail, this.color);
}

class _PillarTile extends StatelessWidget {
  const _PillarTile({required this.data});
  final _PillarItem data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            data.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: data.color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.detail,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.4),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
