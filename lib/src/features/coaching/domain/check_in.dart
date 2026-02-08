import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  final String id;
  final DateTime date;
  final double weight;
  final double waist;
  final double neck;
  final double? hip;
  final int feelingScore; // 1-5

  CheckIn({
    required this.id,
    required this.date,
    required this.weight,
    required this.waist,
    required this.neck,
    this.hip,
    required this.feelingScore,
  });

  factory CheckIn.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckIn(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      waist: (data['waist'] as num).toDouble(),
      neck: (data['neck'] as num).toDouble(),
      hip: (data['hip'] as num?)?.toDouble(),
      feelingScore: data['feelingScore'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'waist': waist,
      'neck': neck,
      'hip': hip,
      'feelingScore': feelingScore,
    };
  }
}
