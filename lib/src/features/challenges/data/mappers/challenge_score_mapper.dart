// SPEC-263: mapeo ChallengeScore <-> Map de Firestore.

import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';

class ChallengeScoreMapper {
  const ChallengeScoreMapper();

  ChallengeScore fromMap(Map<String, dynamic> data) {
    return ChallengeScore(
      uid: (data['uid'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? 'Usuario',
      points: (data['points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap(ChallengeScore s) {
    return {
      'uid': s.uid,
      'displayName': s.displayName,
      'points': s.points,
    };
  }
}
