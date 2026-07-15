// Rediseño "Insignias como pantalla independiente" (15-jul, respuesta a
// feedback de Carlos): el trío AvancesHeader + TuCaminoTimeline +
// BadgeGallery vivía embebido en el ListView de Perfil, entre secciones de
// configuración de cuenta (datos biométricos, ritmos circadianos, legal).
// Eso alargaba demasiado el scroll de Perfil y mezclaba contenido de
// identidad/celebración con contenido administrativo — dos tonos distintos
// en la misma pantalla.
//
// Se evaluó fusionar esto con alguna de las pantallas ya llamadas
// "progreso" en la app (el tab "Progreso" del bottom nav, que en realidad
// apunta a /analysis y está definido explícitamente como revisión
// histórica NO motivacional; o /progress "Mi Avance", centrada en
// evolución biométrica/IMR). Ambas ya están densas y ninguna encaja en
// tono con insignias — se descartó a propósito, no por omisión.
//
// Solución: pantalla propia, empujada desde Perfil (mismo patrón que
// /profile/body-composition), con su propio AppBar. Perfil solo muestra
// una card de entrada compacta (ProfileBadgesEntryCard) con el resumen.
// El contenido interno (los 3 widgets) no cambió — solo se reubicó.

import 'package:flutter/material.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/badges/presentation/widgets/avances_header.dart';
import 'package:elena_app/src/features/badges/presentation/widgets/badge_gallery.dart';
import 'package:elena_app/src/features/badges/presentation/widgets/tu_camino_timeline.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Insignias',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: const [
          AvancesHeader(),
          SizedBox(height: 18),
          TuCaminoTimeline(),
          SizedBox(height: 18),
          BadgeGallery(),
        ],
      ),
    );
  }
}
