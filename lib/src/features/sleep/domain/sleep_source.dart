// SPEC-302 — Procedencia de un registro de sueño, para etiquetarla en la UI.
//
// Jerarquía (decisión de Carlos): la fuente primaria es el dispositivo (Apple
// Health / Health Connect); si no hay, lo que registra el usuario a mano; y si
// no hay ninguno, el estimado del perfil (onboarding, SPEC-303). Un registro
// manual solo existe si el usuario lo ingresó (= una edición), así que el
// dispositivo nunca pisa una edición manual — la regla se cumple sola.

enum SleepSource {
  /// Sincronizado desde Apple Health / Health Connect (reloj, anillo, etc.).
  device,

  /// Ingresado o editado por el usuario a mano.
  manual,

  /// Estimado a partir del perfil (onboarding) cuando no hay dato real.
  estimated;

  String get wire => switch (this) {
        SleepSource.device => 'device',
        SleepSource.manual => 'manual',
        SleepSource.estimated => 'estimated',
      };

  static SleepSource fromWire(String? w) => switch (w) {
        'device' => SleepSource.device,
        'estimated' => SleepSource.estimated,
        _ => SleepSource.manual,
      };

  String get label => switch (this) {
        SleepSource.device => 'Sincronizado',
        SleepSource.manual => 'Manual',
        SleepSource.estimated => 'Estimado',
      };
}
