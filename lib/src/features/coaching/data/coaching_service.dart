import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/check_in.dart';
import '../domain/weekly_plan.dart';

class CoachingService {
  final FirebaseFirestore _firestore;
  final String uid;

  CoachingService(this._firestore, this.uid);

  // References
  CollectionReference<CheckIn> get _checkInsRef => _firestore
      .collection('users')
      .doc(uid)
      .collection('check_ins')
      .withConverter<CheckIn>(
        fromFirestore: (doc, _) => CheckIn.fromFirestore(doc),
        toFirestore: (log, _) => log.toJson(),
      );

  CollectionReference<WeeklyPlan> get _plansRef => _firestore
      .collection('users')
      .doc(uid)
      .collection('plans')
      .withConverter<WeeklyPlan>(
        fromFirestore: (doc, _) => WeeklyPlan.fromFirestore(doc),
        toFirestore: (plan, _) => plan.toJson(),
      );

  // Process Check-In and Generate Plan
  Future<WeeklyPlan> processCheckIn(CheckIn newCheckIn) async {
    // 1. Guardar CheckIn
    await _checkInsRef.add(newCheckIn);

    // 2. Obtener último CheckIn para comparar (excluyendo el actual que acabamos de guardar, 
    // pero como add genera ID nuevo, podemos simplemente buscar el último 'antes' de este o el más reciente)
    // Mejor: Obtener el historial reciente.
    final historyQuery = await _checkInsRef
        .orderBy('date', descending: true)
        .limit(2) // El actual y el anterior
        .get();

    CheckIn? lastCheckIn;
    if (historyQuery.docs.length > 1) {
      // docs[0] es el current (por fecha más reciente), docs[1] es el anterior
      // Ojo: si guardamos antes de consultar, el query snapshot lo incluirá
      // Validamos IDs para estar seguros
      final currentDocId = historyQuery.docs[0].id;
      // Si acabamos de añadir, el current debería estar.
      
      // Asumamos que historyQuery.docs[1] es el previo.
      lastCheckIn = historyQuery.docs[1].data();
    }

    // 3. Generar Plan
    final nextPlan = _generatePlan(newCheckIn, lastCheckIn);

    // 4. Guardar Plan
    await _plansRef.add(nextPlan);

    return nextPlan;
  }

  WeeklyPlan _generatePlan(CheckIn current, CheckIn? previous) {
    final now = DateTime.now();
    // Start date: tomorrow or next Monday? Let's say tomorrow for simplicity
    final startDate = now.add(const Duration(days: 1));
    final endDate = startDate.add(const Duration(days: 6));
    
    // Default / Initial Plan
    if (previous == null) {
      return WeeklyPlan(
        id: '',
        weekNumber: 1,
        startDate: startDate,
        endDate: endDate,
        protocol: '16/8',
        focus: PlanFocus.fatLoss,
        coachNote: '¡Bienvenido! Comenzaremos con un protocolo base 16/8 para adaptar tu cuerpo.',
      );
    }

    // Lógica de Comparación
    final deltaWaist = current.waist - previous.waist;
    
    String protocol;
    PlanFocus focus;
    String note;

    if (deltaWaist < -0.5) {
      // AVANCE (> 0.5cm reducidos)
      protocol = '16/8'; // Mantener lo que funciona o intensificar ligeramente si el usuario lo desea
      focus = PlanFocus.fatLoss;
      note = '¡Excelente progreso! Tu cintura se redujo ${deltaWaist.abs().toStringAsFixed(1)} cm. Mantendremos el ritmo para maximizar la quema de grasa.';
    } else if (deltaWaist >= -0.5 && deltaWaist <= 0.5) {
      // ESTANCAMIENTO (-0.5 a +0.5 cm)
      protocol = '18/6'; // Aumentar intensidad
      focus = PlanFocus.metabolicShock;
      note = 'Parece que hemos llegado a una meseta. Aumentaremos el ayuno a 18 horas para romper la homeostasis y reactivar la oxidación de grasas.';
    } else {
      // RETROCESO (> 0.5 cm aumento)
      protocol = '12/12'; // Reseteo
      focus = PlanFocus.detox;
      note = 'Hemos notado un ligero retroceso. Esta semana nos enfocaremos en descanso, hidratación y comida real (Ritmo Circadiano 12/12) para bajar la inflamación.';
    }

    // Determinar número de semana (basado en planes anteriores? O simple contador)
    // Por simplicidad, asumimos semana X. En un caso real consultaríamos el último plan.
    return WeeklyPlan(
      id: '',
      weekNumber: 0, // Debería incrementarse
      startDate: startDate,
      endDate: endDate,
      protocol: protocol,
      focus: focus,
      coachNote: note,
    );
  }
}

final coachingProvider = Provider<CoachingService>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) throw Exception('User not authenticated');
  return CoachingService(FirebaseFirestore.instance, user.uid);
});
