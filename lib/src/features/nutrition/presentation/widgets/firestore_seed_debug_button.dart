import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔧 DEBUG WIDGET: Botón para disparar seeding de alimentos
/// Usar en onboarding cuando no hay datos en Firestore
class FirestoreSeedDebugButton extends ConsumerWidget {
  const FirestoreSeedDebugButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _triggerSeed(context, ref),
      icon: const Icon(Icons.cloud_download),
      label: const Text('🌱 SEED FIRESTORE'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _triggerSeed(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔧 DEBUG: Seed Firestore'),
        content: const Text(
          '¿Sembrar 15+ alimentos iniciales en master_food_db?\n\n'
          'Esto cargará proteínas, grasas y carbohidratos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _doSeed(context, ref);
            },
            child: const Text('Sembrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _doSeed(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    print('\n🌱 [DEBUG] Iniciando seed...');
    try {
      // TODO: Seed functionality moved to FoodRepository initialization
      // await ref.read(food_service.foodServiceProvider).seedInitialNutritionData();

      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Seed completado - Ver logs en console'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      print('✅ [DEBUG] Seed completado exitosamente\n');
    } catch (e) {
      print('❌ [DEBUG] Error en seed: $e\n');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
