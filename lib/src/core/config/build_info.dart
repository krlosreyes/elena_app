// Identidad del binario que el usuario tiene instalado (29-jul).
//
// POR QUÉ EXISTE: durante el barrido de coherencia se perdieron dos
// compilaciones enteras persiguiendo "los cambios no se ven en el
// iPhone". El binario era correcto —lo comprobamos abriendo el .ipa y
// buscando los textos nuevos dentro del snapshot— pero desde fuera no
// había manera de distinguir tres cosas muy distintas:
//
//   1. el código no llegó al build,
//   2. el build no llegó al teléfono,
//   3. el teléfono tiene un build viejo instalado.
//
// Sin un número visible en pantalla, las tres se ven idénticas: una app
// que "no cambió". Esto las separa en un vistazo.
//
// CÓMO SE RELLENA: `scripts/release_ios.sh` ya calcula el número de
// build para escribirlo en pubspec.yaml; ahora además se lo pasa al
// compilador con `--dart-define`. A propósito NO se usa
// `package_info_plus`: añadir un plugin nativo obliga a `pod install` y
// mete riesgo de build justo en la herramienta que existe para
// diagnosticar problemas de build.
abstract class BuildInfo {
  const BuildInfo._();

  /// Versión legible del producto. Se inyecta desde pubspec.yaml.
  static const String version =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  /// Número de build. `dev` cuando se corre con `flutter run` o en el
  /// Simulador, porque ahí no pasa por el script de release — y eso ya
  /// es información: si el teléfono dice "dev", no está corriendo un
  /// build de distribución.
  static const String buildNumber =
      String.fromEnvironment('BUILD_NUMBER', defaultValue: 'dev');

  /// Lo que se pinta al pie del Perfil: "Versión 1.0.0 · build 55".
  static String get label => 'Versión $version · build $buildNumber';
}
