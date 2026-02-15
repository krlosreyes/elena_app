import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'daily_routine_provider.g.dart';

@riverpod
class DailyRoutine extends _$DailyRoutine {
  @override
  List<Map<String, dynamic>> build() {
    return [
      {
        'id': 'e1',
        'name': 'Sentadilla Goblet',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '10-12', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '10-12', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '10-12', 'weight': null, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'e2',
        'name': 'Flexiones (Push-ups)',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': 'Al fallo', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': 'Al fallo', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': 'Al fallo', 'weight': null, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'e3',
        'name': 'Remo con Mancuernas',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '10-12', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '10-12', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '10-12', 'weight': null, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'e4',
        'name': 'Peso Muerto Rumano (RDL)',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '8-10', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '8-10', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '8-10', 'weight': null, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'e5',
        'name': 'Elevaciones Laterales',
        'targetRir': 3,
        'sets': [
          { 'setIndex': 1, 'targetReps': '12-15', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '12-15', 'weight': null, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '12-15', 'weight': null, 'reps': null, 'isDone': false },
        ]
      },
    ];
  }

  void toggleSet(String exerciseId, int setIndex, double? weight, int? reps) {
    state = [
      for (final exercise in state)
        if (exercise['id'] == exerciseId)
          {
            ...exercise,
            'sets': [
              for (final set in exercise['sets'] as List)
                if (set['setIndex'] == setIndex)
                  {
                    ...set,
                    'isDone': !set['isDone'],
                    'weight': weight,
                    'reps': reps,
                  }
                else
                  set
            ]
          }
        else
          exercise
    ];
  }
}
