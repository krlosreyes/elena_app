// 17-jul (2da vuelta, rediseño Perfil): "Protocolo de ayuno" pasa de
// sección siempre expandida a card colapsada + pantalla de detalle —
// ver comentario en biometricos_detail_screen.dart, mismo movimiento.
// ProfileProtocolCard no cambió — solo dónde vive.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_protocol_card.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class ProtocoloDetailScreen extends ConsumerWidget {
  const ProtocoloDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

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
          'Protocolo de ayuno',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                ProfileProtocolCard(protocol: user.fastingProtocol),
              ],
            ),
          );
        },
      ),
    );
  }
}
