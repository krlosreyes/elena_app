import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../health/data/health_repository.dart';
import '../../../health/domain/daily_log.dart';
import '../../../fasting/application/fasting_controller.dart';
import '../../../../core/widgets/blueprint_grid.dart';

class MealReviewSheet extends ConsumerWidget {
  final String uid;

  const MealReviewSheet({super.key, required this.uid});

  static Future<void> show(BuildContext context, String uid) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MealReviewSheet(uid: uid),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(todayLogProvider(uid));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: BlueprintGrid(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REVISIÓN DE INGESTA',
                            style: GoogleFonts.robotoMono(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text('Detectamos registros previos hoy',
                            style: GoogleFonts.publicSans(
                                color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: logAsync.when(
                  data: (log) => _buildMealList(log),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
              const SizedBox(height: 24),
              _buildActions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealList(DailyLog? log) {
    if (log == null || log.mealEntries.isEmpty) {
      return Center(
        child: Text('No hay comidas registradas.',
            style: GoogleFonts.robotoMono(color: Colors.white24)),
      );
    }

    return ListView.separated(
      itemCount: log.mealEntries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final meal = log.mealEntries[index];
        final time = _parseTime(meal['timestamp']);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Text(
                '#${index + 1}',
                style: GoogleFonts.robotoMono(
                    color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal['name'] ?? 'Comida',
                        style: GoogleFonts.publicSans(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(time,
                        style: GoogleFonts.robotoMono(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                '${meal['calories']} kcal',
                style: GoogleFonts.robotoMono(
                    color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white10),
            ),
          ),
          child: Text('MIS COMIDAS ESTÁN BIEN',
              style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.surface,
                title: const Text('¿BORRAR TODO?'),
                content: const Text('Esta acción limpiará todos los registros de comida de hoy para iniciar una ventana con telemetría pura.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true), 
                    child: const Text('SÍ, BORRAR', style: TextStyle(color: Colors.red))
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await ref.read(healthRepositoryProvider).clearTodayMeals(uid);
              if (context.mounted) {
                Navigator.pop(context);
                // Trigger modal de registro
                ref.read(mealModalTriggerProvider.notifier).state = true;
              }
            }
          },
          child: Text('BORRAR TODO Y EMPEZAR DE CERO',
              style: GoogleFonts.robotoMono(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  String _parseTime(dynamic ts) {
    if (ts == null) return '--:--';
    DateTime dt;
    if (ts is DateTime) {
      dt = ts;
    } else if (ts is String) {
      dt = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }
    return DateFormat('HH:mm').format(dt);
  }
}
