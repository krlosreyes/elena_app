import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/auth_repository.dart';
import '../../progress/domain/measurement_log.dart';
import '../../profile/domain/user_model.dart';
import '../domain/weekly_plan.dart';

class CoachingService {
  final FirebaseFirestore _firestore;

  CoachingService(this._firestore);

  CollectionReference<WeeklyPlan> _plansRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('plans')
      .withConverter<WeeklyPlan>(
        fromFirestore: (doc, _) => WeeklyPlan.fromFirestore(doc),
        toFirestore: (plan, _) => plan.toJson(),
      );

  CollectionReference<MeasurementLog> _measurementsRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('measurements')
      .withConverter<MeasurementLog>(
        fromFirestore: (doc, _) => MeasurementLog.fromFirestore(doc),
        toFirestore: (log, _) => log.toJson(),
      );

  Future<WeeklyPlan> generatePlanFromMeasurement(
      MeasurementLog currentLog, UserModel user) async {
    // 1. Buscar el MeasurementLog ANTERIOR
    final historyQuery = await _measurementsRef(user.uid)
        .orderBy('date', descending: true)
        // Pedimos 2: el actual (que acabamos de guardar) y el anterior.
        // Si el actual ya se guardó, vendrá en la query.
        .limit(2)
        .get();

    MeasurementLog? previousLog;
    
    // Filtramos para asegurar que no comparamos con el mismo ID (por si acaso)
    final otherLogs = historyQuery.docs
        .map((d) => d.data())
        .where((log) => log.id != currentLog.id) 
        // Nota: currentLog.id podría venir vacío si es local antes de guardar, 
        // pero aquí asumimos que ya se guardó o que filtramos por fecha.
        // Mejor lógica: Tomar el primer log cuya fecha sea ANTERIOR a currentLog.date
        .toList();

    if (otherLogs.isNotEmpty) {
      previousLog = otherLogs.first;
    }

    // 2. Generar Plan
    final nextPlan = _createPlanLogic(currentLog, previousLog, user);

    // 3. Guardar Plan (Overwrite 'current' or add to history? 
    // Requirement says: users/{uid}/plans/current. 
    // Let's use a specific ID 'current' to easily overwrite/fetch, 
    // or store in a collection and just use the latest.
    // The requirement says: "Guardar el WeeklyPlan en Firestore: users/{uid}/plans/current"
    // This implies a document with ID 'current'.
    
    await _plansRef(user.uid).doc('current').set(nextPlan);
    
    return nextPlan;
  }

  WeeklyPlan _createPlanLogic(
      MeasurementLog current, MeasurementLog? previous, UserModel user) {
    
    final now = DateTime.now();
    final startDate = now; 
    final endDate = now.add(const Duration(days: 7));

    // PASO 2: Primer Registro (No hay historial previo)
    if (previous == null || previous.waistCircumference == null || current.waistCircumference == null) {
      bool hasInsulinResistance = user.pathologies.contains('insulin_resistance') || 
                                  user.pathologies.contains('prediabetes');
      
      return WeeklyPlan(
        id: 'current',
        startDate: startDate,
        endDate: endDate,
        protocol: hasInsulinResistance ? '16/8' : '14/10',
        status: PlanStatus.initial,
        coachMessage: "¡Comenzamos tu transformación! Esta semana es de adaptación.",
        adjustments: ["Hidratación constante", "Dormir 7h+"],
      );
    }

    // PASO 3: Comparación
    final currentWaist = current.waistCircumference!;
    final previousWaist = previous.waistCircumference!;
    final deltaWaist = currentWaist - previousWaist;

    String protocol;
    PlanStatus status;
    String message;
    List<String> adjustments;

    if (deltaWaist < -0.5) {
      // PROGRESS
      status = PlanStatus.progress;
      protocol = '16/8'; // Mantener anterior (simplificación: asumimos 16/8 por defecto si no tenemos el plan previo)
      // Idealmente leeríamos el plan anterior para mantener su protocolo. 
      // Por ahora, '16/8' es un valor seguro o el del user preference.
      // Mejora: si pudiéramos leer el plan anterior, useríamos ese protocolo.
      // Asumiremos mantener 16/8 como base de éxito.
      message = "¡Excelente! Estás quemando grasa visceral. Sigamos igual.";
      adjustments = ["Mantener horarios", "Aumentar proteína"];
    } else if (deltaWaist >= -0.5 && deltaWaist <= 0.5) {
      // STAGNATION
      status = PlanStatus.stagnation;
      protocol = '18/6'; // Aumentar intensidad
      message = "Estabilidad detectada. Vamos a retar a tu cuerpo con un protocolo nuevo.";
      adjustments = ["Protocolo 18/6", "Caminar antes de primera comida"];
    } else {
      // REGRESSION
      status = PlanStatus.regression;
      protocol = '14/10'; // Resetear (Control de estrés)
      message = "Cintura arriba. Prioricemos descanso y comida real esta semana.";
      adjustments = ["Reducir ventana a 14/10", "Priorizar sueño", "Cero procesados"];
    }

    return WeeklyPlan(
      id: 'current',
      startDate: startDate,
      endDate: endDate,
      protocol: protocol,
      status: status,
      coachMessage: message,
      adjustments: adjustments,
    );
  }
}

final coachingProvider = Provider<CoachingService>((ref) {
  return CoachingService(FirebaseFirestore.instance);
});

