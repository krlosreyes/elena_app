// SPEC-263: mapeo Challenge <-> Map de Firestore.

import 'package:elena_app/src/features/challenges/domain/challenge.dart';

class ChallengeMapper {
  const ChallengeMapper();

  /// [code] es el id del doc; no viaja dentro de `data`.
  Challenge fromMap(String code, Map<String, dynamic> data) {
    return Challenge(
      code: code,
      name: (data['name'] as String?) ?? '',
      ownerId: (data['ownerId'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      startDateKey: (data['startDateKey'] as String?) ?? '',
      endDateKey: (data['endDateKey'] as String?) ?? '',
      memberIds: ((data['memberIds'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  /// NO incluye `code` (es el id del doc).
  Map<String, dynamic> toMap(Challenge c) {
    return {
      'name': c.name,
      'ownerId': c.ownerId,
      'ownerName': c.ownerName,
      'startDateKey': c.startDateKey,
      'endDateKey': c.endDateKey,
      'memberIds': c.memberIds,
    };
  }
}
