// Manuel implementation of serialization to avoid build_runner blockers (SPEC-09)

enum CorrelationType { positive, neutral, negative }

class CorrelationResult {
  final String pilarA;
  final String pilarB;
  final double score;
  final CorrelationType type;
  final String insight;

  const CorrelationResult({
    required this.pilarA,
    required this.pilarB,
    required this.score,
    required this.type,
    required this.insight,
  });

  Map<String, dynamic> toJson() => {
    'pilarA': pilarA,
    'pilarB': pilarB,
    'score': score,
    'type': type.name,
    'insight': insight,
  };

  factory CorrelationResult.fromJson(Map<String, dynamic> json) => CorrelationResult(
    pilarA: json['pilarA'] as String,
    pilarB: json['pilarB'] as String,
    score: (json['score'] as num).toDouble(),
    type: CorrelationType.values.byName(json['type'] as String),
    insight: json['insight'] as String,
  );
}

class WeeklyAnalysis {
  final double avgImr;
  final double adherence;
  final int topPilarInfluenceIndex;
  final String topPilarName;

  const WeeklyAnalysis({
    required this.avgImr,
    required this.adherence,
    required this.topPilarInfluenceIndex,
    required this.topPilarName,
  });

  Map<String, dynamic> toJson() => {
    'avgImr': avgImr,
    'adherence': adherence,
    'topPilarInfluenceIndex': topPilarInfluenceIndex,
    'topPilarName': topPilarName,
  };

  factory WeeklyAnalysis.fromJson(Map<String, dynamic> json) => WeeklyAnalysis(
    avgImr: (json['avgImr'] as num).toDouble(),
    adherence: (json['adherence'] as num).toDouble(),
    topPilarInfluenceIndex: (json['topPilarInfluenceIndex'] as num).toInt(),
    topPilarName: json['topPilarName'] as String,
  );
}

class AnalysisCache {
  final DateTime lastUpdated;
  final List<CorrelationResult> correlations;
  final WeeklyAnalysis currentWeek;
  final WeeklyAnalysis previousWeek;

  AnalysisCache({
    required this.lastUpdated,
    required this.correlations,
    required this.currentWeek,
    required this.previousWeek,
  });

  Map<String, dynamic> toJson() => {
    'lastUpdated': lastUpdated.toIso8601String(),
    'correlations': correlations.map((c) => c.toJson()).toList(),
    'currentWeek': currentWeek.toJson(),
    'previousWeek': previousWeek.toJson(),
  };

  factory AnalysisCache.fromJson(Map<String, dynamic> json) => AnalysisCache(
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    correlations: (json['correlations'] as List).map((c) => CorrelationResult.fromJson(c)).toList(),
    currentWeek: WeeklyAnalysis.fromJson(json['currentWeek']),
    previousWeek: WeeklyAnalysis.fromJson(json['previousWeek']),
  );
}
