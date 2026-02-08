class FastingHelper {
  static String getBenefit(Duration elapsed) {
    if (elapsed.inHours < 12) {
      return 'Descanso digestivo y estabilización de glucosa.';
    } else if (elapsed.inHours < 14) {
      return 'Quema de grasa activa.';
    } else if (elapsed.inHours < 16) {
      return 'Cetosis y claridad mental.';
    } else {
      return 'Autofagia y regeneración celular.';
    }
  }
}
