// SPEC-301 — Etapas del sueño de una noche, cuando el dispositivo del usuario
// (Apple Watch, Galaxy Watch, anillo, etc.) las mide. Minutos por etapa.
//
// Pure Dart. `awake` = despierto DENTRO de la ventana de sueño (fragmentación),
// no cuenta como sueño. `asleepMinutes` = profundo + ligero + REM.
//
// Ciencia (se usa en la narrativa de impacto, SPEC-304): el sueño profundo
// (ondas lentas) concentra la secreción de hormona de crecimiento y la
// reparación metabólica; el REM regula apetito/cortisol; la fragmentación
// (despertares) se asocia a peor sensibilidad a la insulina.

class SleepStages {
  final int deepMinutes;
  final int remMinutes;
  final int lightMinutes;
  final int awakeMinutes;

  const SleepStages({
    this.deepMinutes = 0,
    this.remMinutes = 0,
    this.lightMinutes = 0,
    this.awakeMinutes = 0,
  });

  /// Minutos realmente dormidos (sin contar despierto).
  int get asleepMinutes => deepMinutes + remMinutes + lightMinutes;

  /// Minutos totales en la ventana (incluye despierto).
  int get totalMinutes => asleepMinutes + awakeMinutes;

  /// True si hay AL MENOS una etapa medida (profundo/ligero/REM). Solo
  /// entonces se muestra el desglose; `awake` solo no basta.
  bool get hasData => deepMinutes > 0 || remMinutes > 0 || lightMinutes > 0;

  double _fracOf(int m) => asleepMinutes <= 0 ? 0 : m / asleepMinutes;

  /// Fracción [0..1] de cada etapa respecto al sueño real.
  double get deepFraction => _fracOf(deepMinutes);
  double get remFraction => _fracOf(remMinutes);
  double get lightFraction => _fracOf(lightMinutes);

  /// Construye desde el mapa que emite el pipeline de HealthKit/Health Connect
  /// ({'deep': m, 'rem': m, 'light': m, 'awake': m}). Null/vacío → null.
  static SleepStages? fromHealthMap(Map<String, int>? m) {
    if (m == null || m.isEmpty) return null;
    final s = SleepStages(
      deepMinutes: m['deep'] ?? 0,
      remMinutes: m['rem'] ?? 0,
      lightMinutes: m['light'] ?? 0,
      awakeMinutes: m['awake'] ?? 0,
    );
    return s.hasData ? s : null;
  }

  Map<String, dynamic> toMap() => {
        if (deepMinutes > 0) 'deep': deepMinutes,
        if (remMinutes > 0) 'rem': remMinutes,
        if (lightMinutes > 0) 'light': lightMinutes,
        if (awakeMinutes > 0) 'awake': awakeMinutes,
      };

  static SleepStages? fromMap(Map<String, dynamic>? m) {
    if (m == null || m.isEmpty) return null;
    int v(String k) => (m[k] as num?)?.toInt() ?? 0;
    final s = SleepStages(
      deepMinutes: v('deep'),
      remMinutes: v('rem'),
      lightMinutes: v('light'),
      awakeMinutes: v('awake'),
    );
    return s.hasData ? s : null;
  }

  @override
  bool operator ==(Object other) =>
      other is SleepStages &&
      other.deepMinutes == deepMinutes &&
      other.remMinutes == remMinutes &&
      other.lightMinutes == lightMinutes &&
      other.awakeMinutes == awakeMinutes;

  @override
  int get hashCode =>
      Object.hash(deepMinutes, remMinutes, lightMinutes, awakeMinutes);
}
