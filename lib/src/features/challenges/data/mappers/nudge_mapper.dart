// SPEC-264: mapeo Nudge <-> Map de Firestore.

import 'package:elena_app/src/features/challenges/domain/nudge.dart';

class NudgeMapper {
  const NudgeMapper();

  Nudge fromMap(Map<String, dynamic> data) {
    final millis = (data['createdAt'] as num?)?.toInt() ?? 0;
    return Nudge(
      id: (data['id'] as String?) ?? '',
      fromUid: (data['fromUid'] as String?) ?? '',
      fromName: (data['fromName'] as String?) ?? 'Alguien',
      toUid: (data['toUid'] as String?) ?? '',
      typeId: (data['typeId'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }

  /// NO incluye `id` (es el id del doc autogenerado).
  Map<String, dynamic> toMap(Nudge n) => {
        'fromUid': n.fromUid,
        'fromName': n.fromName,
        'toUid': n.toUid,
        'typeId': n.typeId,
        'createdAt': n.createdAt.millisecondsSinceEpoch,
      };
}
