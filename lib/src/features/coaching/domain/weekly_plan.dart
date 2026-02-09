import 'package:cloud_firestore/cloud_firestore.dart';


enum PlanStatus { progress, stagnation, regression, initial }

class WeeklyPlan {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String protocol; // e.g., "16/8"
  final PlanStatus status;
  final String coachMessage;
  final List<String> adjustments;

  WeeklyPlan({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.protocol,
    required this.status,
    required this.coachMessage,
    required this.adjustments,
  });

  factory WeeklyPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklyPlan(
      id: doc.id,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      protocol: data['protocol'] as String,
      status: PlanStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PlanStatus.initial,
      ),
      coachMessage: data['coachMessage'] as String,
      adjustments: List<String>.from(data['adjustments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'protocol': protocol,
      'status': status.name,
      'coachMessage': coachMessage,
      'adjustments': adjustments,
    };
  }
}

