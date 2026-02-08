import 'package:cloud_firestore/cloud_firestore.dart';

enum PlanFocus { fatLoss, maintenance, metabolicShock, detox }

class WeeklyPlan {
  final String id;
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String protocol; // e.g., "16/8"
  final PlanFocus focus;
  final String coachNote;

  WeeklyPlan({
    required this.id,
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.protocol,
    required this.focus,
    required this.coachNote,
  });

  factory WeeklyPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklyPlan(
      id: doc.id,
      weekNumber: data['weekNumber'] as int,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      protocol: data['protocol'] as String,
      focus: PlanFocus.values.firstWhere((e) => e.name == data['focus']),
      coachNote: data['coachNote'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'protocol': protocol,
      'focus': focus.name,
      'coachNote': coachNote,
    };
  }
}
