import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/biometric_calculator.dart';
import 'user_controller.dart';



// ─────────────────────────────────────────────────────────────────────────────
// BIOMETRIC PROVIDERS — Riverpod State Management
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the complete biometric calculation result for the current user
///
/// Dependencies:
/// - currentUserStreamProvider: Fetches user data from Firestore
///
/// Automatically recalculates when user data changes (biometric measurements).
/// Read-only provider. Use AsyncValue to handle loading/error states.
final biometricResultProvider =
    FutureProvider.autoDispose<BiometricResult>((ref) async {
  // Fetch current user from stream provider
  final userAsync = await ref.watch(currentUserStreamProvider.future);

  if (userAsync == null) {
    throw Exception('Usuario no autenticado');
  }

  // Generate complete biometric profile
  try {
    final result = BiometricCalculator.generateProfile(user: userAsync);
    return result;
  } catch (e) {
    throw Exception('Error calculando perfil biométrico: $e');
  }
});

/// Provides BMI specific value
final bmiProvider = FutureProvider.autoDispose<double>((ref) async {
  final result = await ref.watch(biometricResultProvider.future);
  return result.bmi;
});

/// Provides body fat percentage
final bodyFatPercentageProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final result = await ref.watch(biometricResultProvider.future);
  return result.bodyFatPercentage;
});

/// Provides lean body mass in kg
final leanBodyMassProvider = FutureProvider.autoDispose<double>((ref) async {
  final result = await ref.watch(biometricResultProvider.future);
  return result.leanBodyMassKg;
});

/// Provides IMR risk level
final imrRiskLevelProvider =
    FutureProvider.autoDispose<IMRRiskLevel>((ref) async {
  final result = await ref.watch(biometricResultProvider.future);
  return result.imrRiskLevel;
});

/// Provides waist-to-height ratio
final waistToHeightRatioProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final result = await ref.watch(biometricResultProvider.future);
  return result.waistToHeightRatio;
});

/// Provides color for IMR hotspot based on risk level
final imrColorProvider = FutureProvider.autoDispose<Color>((ref) async {
  final result = await ref.watch(biometricResultProvider.future);
  final hex = result.getIMRColor();
  return Color(int.parse(hex.replaceFirst('#', '0xFF')));
});

/// Helper provider to get risk description
final riskDescriptionProvider = FutureProvider.autoDispose<String>((ref) async {
  final result = await ref.watch(biometricResultProvider.future);
  return result.riskDescription;
});
