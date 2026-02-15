import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/auth_repository.dart';
import '../../fasting/data/fasting_repository.dart';
import '../../fasting/domain/fasting_session.dart';

// STRICT: AutoDispose + Explicit Auth Watch
// This ensures that when the cached User ID changes, the stream is strictly rebuilt.
// Prevents exposing Stream data from User A to User B.
final activeFastProvider = StreamProvider.autoDispose<FastingSession?>((ref) {
  // 1. WATCH Auth State
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  // 2. Guard Clause: If no user, return empty stream immediately.
  if (user == null) {
    return const Stream.empty(); 
  }

  // 3. User Active: Watch Repository and subscribe to specific UID stream.
  final repository = ref.watch(fastingRepositoryProvider);
  
  // 4. Return the stream for the SPECIFIC UID. 
  // Because we watch 'authState', any change in UID creates a new stream.
  return repository.getActiveFastStream(user.uid);
});
