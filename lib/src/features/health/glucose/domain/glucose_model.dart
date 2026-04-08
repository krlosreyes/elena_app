import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GlucoseLog {
  final String id;
  final double value; // mg/dL
  final DateTime timestamp;
  final String tag; // Ayunas, Post-comida, Antes de dormir

  GlucoseLog({
    required this.id,
    required this.value,
    required this.timestamp,
    required this.tag,
  });

  // --- Business Logic (Traffic Light) ---
  Color get statusColor {
    if (value < 70) return Colors.red; // Hypo
    if (value <= 100) return Colors.green; // Normal
    if (value <= 125) return Colors.orange; // Prediabetes
    return Colors.red; // Diabetes
  }

  // --- Serialization ---

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'timestamp': Timestamp.fromDate(timestamp),
      'tag': tag,
    };
  }

  factory GlucoseLog.fromMap(Map<String, dynamic> map, String id) {
    return GlucoseLog(
      id: id,
      value: (map['value'] as num).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      tag: map['tag'] as String,
    );
  }

  GlucoseLog copyWith({
    String? id,
    double? value,
    DateTime? timestamp,
    String? tag,
  }) {
    return GlucoseLog(
      id: id ?? this.id,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      tag: tag ?? this.tag,
    );
  }
}
