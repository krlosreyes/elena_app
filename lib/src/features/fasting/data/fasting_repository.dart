import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/fasting_session.dart';

class FastingRepository {
  final FirebaseFirestore _firestore;

  FastingRepository(this._firestore);

  /// Starts a new fast. 
  /// STRICT: Always requires [uid]. Stateless.
  Future<void> startFast(String uid, FastingSession session) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('fasting_history')
          .add(session.toJson());
    } catch (e) {
      throw Exception('Error starting fast: $e');
    }
  }

  /// Saves a completed fast. 
  /// STRICT: Smart detection for Retroactive vs Active fasts.
  /// If [session] matches the start time of the specific ACTIVE fast in Firestore, it updates it (closes it).
  /// Otherwise, it treats it as a separate (past) log and adds a new document.
  Future<void> saveCompletedFast(String uid, FastingSession session) async {
    try {
      final colRef = _firestore.collection('users').doc(uid).collection('fasting_history');
      
      // 1. Get the current ACTIVE fast (if any)
      final activeSnapshot = await colRef
          .where('isCompleted', isEqualTo: false)
          .limit(1)
          .get();

      bool isUpdatingActive = false;
      String? docIdToUpdate;

      if (activeSnapshot.docs.isNotEmpty) {
        final activeDoc = activeSnapshot.docs.first;
        final activeData = activeDoc.data();
        
        // STRICT CHECK: Compare Start Times (with tolerance for ms precision loss)
        // If the session we are saving has the ~same start time as the active one, 
        // we assume we are CLOSING the active fast.
        DateTime activeStartTime;
        final rawStart = activeData['startTime'];
        if (rawStart is Timestamp) {
          activeStartTime = rawStart.toDate();
        } else if (rawStart is String) {
          activeStartTime = DateTime.parse(rawStart);
        } else {
          // Fallback safely if type is unknown
          activeStartTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        final diff = activeStartTime.difference(session.startTime).inSeconds.abs();
        
        if (diff < 60) { // 60 seconds tolerance to match the active session
          isUpdatingActive = true;
          docIdToUpdate = activeDoc.id;
        }
      }

      if (isUpdatingActive && docIdToUpdate != null) {
        // UPDATE existing Active Fast -> Closed
        await colRef.doc(docIdToUpdate).update(session.toJson());
      } else {
        // Log as NEW entry (Retroactive Fast)
        // This ensures we don't accidentally close an unrelated active fast.
        await colRef.add(session.toJson());
      }

    } catch (e) {
      throw Exception('Error saving completed fast: $e');
    }
  }

  Stream<List<FastingSession>> getHistoryStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FastingSession.fromJson(_firestoreToJson(doc.data())))
            .toList());
  }

  Stream<FastingSession?> getActiveFastStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history') 
        .where('isCompleted', isEqualTo: false) 
        // .orderBy('startTime', descending: true) // REMOVED to avoid index error
        // .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          
          final sessions = snapshot.docs
              .map((doc) => FastingSession.fromJson(_firestoreToJson(doc.data())))
              .toList();

          // Ordenamiento en cliente (Memory Sort): Descendente por fecha
          sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
          
          return sessions.first;
        });
  }

  /// Helper to convert Firestore Types (Timestamp) to Json Types (String)
  /// compatible with generated fromJson.
  Map<String, dynamic> _firestoreToJson(Map<String, dynamic> data) {
    final json = Map<String, dynamic>.from(data);
    
    if (json['startTime'] is Timestamp) {
      json['startTime'] = (json['startTime'] as Timestamp).toDate().toIso8601String();
    }
    
    if (json['endTime'] is Timestamp) {
      json['endTime'] = (json['endTime'] as Timestamp).toDate().toIso8601String();
    }

    return json;
  }
}

final fastingRepositoryProvider = Provider<FastingRepository>((ref) {
  return FastingRepository(FirebaseFirestore.instance);
});
