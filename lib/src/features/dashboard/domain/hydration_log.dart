import 'package:flutter/material.dart';

class HydrationLog {
  final double amountInLiters;
  final DateTime timestamp;
  final String type; // Por si luego diferenciamos entre agua, infusiones, etc.

  HydrationLog({
    required this.amountInLiters,
    required this.timestamp,
    this.type = 'Agua',
  });

  // Factory para crear registros rápidos (ej: un vaso de 250ml)
  factory HydrationLog.glass() => HydrationLog(
    amountInLiters: 0.250,
    timestamp: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'amount': amountInLiters,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
  };

  factory HydrationLog.fromJson(Map<String, dynamic> json) => HydrationLog(
    amountInLiters: (json['amount'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
    type: json['type'] ?? 'Agua',
  );
}