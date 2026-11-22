// SPEC-305 — Fuentes científicas verificables (Guía 1.4.1 de App Store).
//
// POR QUÉ EXISTE
// --------------
// 22-nov-2026: App Review rechazó la 1.0 (build 84) por la guía 1.4.1
// (Safety — Physical Harm): "the app provides health or medical
// calculations ... without citations, such as links to sources". La app
// ya citaba autores en varios sitios, pero como texto plano, gris, sin
// enlace, y en muchos casos solo en comentarios del código. Para Apple —y
// para el usuario— una cita que no se puede abrir no es verificable.
//
// Este archivo es la ÚNICA fuente de verdad de las referencias que la app
// muestra. Cada entrada tiene un enlace estable (PubMed, DOI, OMS, DTIC o
// la editorial) comprobado el 22-nov-2026 contra la base de PubMed
// (E-utilities) o la página del editor, y de nuevo el 22-nov abriendo cada
// enlace en un navegador real (se retiraron DTIC, ScienceDirect, Open Library
// y CORE por mantenimiento o controles anti-bots).
//
// Reglas:
//   1. Toda cita visible en la app debe resolver a una entrada de aquí.
//      `test/features/science/citation_coverage_test.dart` lo verifica
//      barriendo todas las cadenas de `lib/`. Si agregas una cita nueva sin
//      su fuente, el test falla.
//   2. Antes de añadir una entrada, comprobar que el enlace abre el trabajo
//      correcto (autor, año, título). Una cita que lleva a otro artículo es
//      peor que ninguna.
//   3. Solo fuentes primarias, consensos o guías oficiales. Nada de
//      podcasts, blogs ni marcas comerciales (ver `forbiddenCitations`).

import 'package:flutter/foundation.dart';

/// Pilar o área de la app que respalda una fuente. Ordena la pantalla de
/// "Fuentes científicas".
enum SourceCategory {
  bodyComposition('Composición corporal e IMC'),
  fasting('Ayuno y ventana de alimentación'),
  nutrition('Alimentación'),
  sleep('Sueño'),
  hydration('Hidratación'),
  exercise('Ejercicio'),
  glucose('Glucosa'),
  habits('Hábitos y constancia');

  const SourceCategory(this.label);
  final String label;
}

@immutable
class ScientificSource {
  const ScientificSource({
    required this.id,
    required this.shortLabel,
    required this.authors,
    required this.year,
    required this.title,
    required this.venue,
    required this.url,
    required this.category,
    required this.supports,
    required this.matchTerms,
  });

  /// Identificador estable. Lo usan las pantallas para pedir sus fuentes
  /// (`SourcesFooter(ids: [...])`).
  final String id;

  /// Cómo se ve en una línea: "Ashwell et al., 2012".
  final String shortLabel;
  final String authors;
  final int year;
  final String title;

  /// Revista, editorial u organismo.
  final String venue;

  /// Enlace público y estable al trabajo.
  final String url;
  final SourceCategory category;

  /// Qué respalda dentro de Elena, en lenguaje de usuario.
  final String supports;

  /// Términos que identifican esta fuente dentro de una cita corta
  /// ("Walker 2017 + AASM"). Se comparan normalizados (minúsculas, sin
  /// tildes ni puntuación) y por palabra completa.
  final List<String> matchTerms;
}

/// Catálogo de fuentes. Verificado el 22-nov-2026.
abstract final class ScientificSources {
  // ── Composición corporal e IMC ──────────────────────────────────────────
  static const whoBmi = ScientificSource(
    id: 'who_bmi',
    shortLabel: 'OMS, 2000',
    authors: 'Organización Mundial de la Salud',
    year: 2000,
    title: 'Obesity: preventing and managing the global epidemic. '
        'Report of a WHO consultation (WHO Technical Report Series 894)',
    venue: 'OMS',
    url: 'https://iris.who.int/handle/10665/42330',
    category: SourceCategory.bodyComposition,
    supports: 'Clasificación del IMC. Por debajo de 18.5 es bajo peso: ahí '
        'Elena no habilita el ayuno.',
    matchTerms: ['oms imc', 'who bmi', 'oms 2000'],
  );

  // 22-nov: los informes originales de 1984 solo están en DTIC (apps.dtic.mil),
  // que entra en mantenimiento y no es fiable para un enlace dentro de la app.
  // Se enlaza el capítulo del propio Hodgdon en NCBI Bookshelf (NIH), que
  // describe cómo la US Navy desarrolló y usa estas ecuaciones, y una
  // validación independiente indexada en PubMed.
  static const navyHodgdon = ScientificSource(
    id: 'navy_hodgdon_1992',
    shortLabel: 'Hodgdon, 1992 — fórmula US Navy',
    authors: 'Hodgdon JA',
    year: 1992,
    title: 'Body Composition in the Military Services: Standards and Methods. '
        'En: Body Composition and Physical Performance',
    venue: 'National Academies Press (NCBI Bookshelf)',
    url: 'https://www.ncbi.nlm.nih.gov/books/NBK235939/',
    category: SourceCategory.bodyComposition,
    supports: 'La fórmula de circunferencias de la US Navy con la que '
        'estimamos tu % de grasa (cintura, cuello y estatura; en mujeres, '
        'también cadera).',
    matchTerms: ['hodgdon', 'us navy', 'formula naval'],
  );

  static const navyShake = ScientificSource(
    id: 'navy_shake_1993',
    shortLabel: 'Shake et al., 1993',
    authors: 'Shake CL, Schlichting C, Mooney LW, Callahan AB, Cohen ME',
    year: 1993,
    title: 'Predicting percent body fat from circumference measurements',
    venue: 'Military Medicine',
    url: 'https://pubmed.ncbi.nlm.nih.gov/8437737/',
    category: SourceCategory.bodyComposition,
    supports: 'Validación de la fórmula US Navy contra pesaje hidrostático, '
        'con su margen de error: es una estimación, no una medición exacta.',
    matchTerms: ['shake', 'us navy', 'formula naval'],
  );


  static const ashwell2012 = ScientificSource(
    id: 'ashwell_2012',
    shortLabel: 'Ashwell et al., 2012',
    authors: 'Ashwell M, Gunn P, Gibson S',
    year: 2012,
    title: 'Waist-to-height ratio is a better screening tool than waist '
        'circumference and BMI for adult cardiometabolic risk factors: '
        'systematic review and meta-analysis',
    venue: 'Obesity Reviews',
    url: 'https://pubmed.ncbi.nlm.nih.gov/22106927/',
    category: SourceCategory.bodyComposition,
    supports: 'Índice cintura-estatura y su punto de corte de 0.5 como '
        'señal de riesgo cardiometabólico.',
    matchTerms: ['ashwell'],
  );

  static const kouri1995 = ScientificSource(
    id: 'kouri_1995',
    shortLabel: 'Kouri et al., 1995',
    authors: 'Kouri EM, Pope HG Jr, Katz DL, Oliva P',
    year: 1995,
    title: 'Fat-free mass index in users and nonusers of '
        'anabolic-androgenic steroids',
    venue: 'Clinical Journal of Sport Medicine',
    url: 'https://pubmed.ncbi.nlm.nih.gov/7496846/',
    category: SourceCategory.bodyComposition,
    supports: 'Índice de masa libre de grasa (FFMI) y sus rangos de '
        'referencia.',
    matchTerms: ['kouri', 'ffmi'],
  );

  static const aceBodyFat = ScientificSource(
    id: 'ace_body_fat',
    shortLabel: 'American Council on Exercise (ACE)',
    authors: 'American Council on Exercise',
    year: 2014,
    title: 'Categorías de porcentaje de grasa corporal (ACE Personal '
        'Trainer Manual)',
    venue: 'ACE',
    url: 'https://www.acefitness.org/about-ace/press-room/in-the-news/8602/',
    category: SourceCategory.bodyComposition,
    supports: 'Rangos de % de grasa (esencial, atlético, fitness, promedio, '
        'alto) por sexo.',
    matchTerms: ['ace', 'american council on exercise'],
  );

  static const gallagher2000 = ScientificSource(
    id: 'gallagher_2000',
    shortLabel: 'Gallagher et al., 2000',
    authors: 'Gallagher D, Heymsfield SB, Heo M, et al.',
    year: 2000,
    title: 'Healthy percentage body fat ranges: an approach for developing '
        'guidelines based on body mass index',
    venue: 'American Journal of Clinical Nutrition',
    url: 'https://pubmed.ncbi.nlm.nih.gov/10966886/',
    category: SourceCategory.bodyComposition,
    supports: 'Rangos saludables de % de grasa según sexo y edad, con base '
        'clínica.',
    matchTerms: ['gallagher'],
  );

  // ── Ayuno y ventana ─────────────────────────────────────────────────────
  static const deCabo2019 = ScientificSource(
    id: 'decabo_2019',
    shortLabel: 'de Cabo & Mattson, 2019',
    authors: 'de Cabo R, Mattson MP',
    year: 2019,
    title: 'Effects of Intermittent Fasting on Health, Aging, and Disease',
    venue: 'New England Journal of Medicine',
    url: 'https://pubmed.ncbi.nlm.nih.gov/31881139/',
    category: SourceCategory.fasting,
    supports: 'Beneficios y contraindicaciones del ayuno intermitente '
        '(embarazo, bajo peso, trastornos alimentarios, diabetes medicada).',
    matchTerms: ['de cabo', 'cabo'],
  );

  static const mattson2017 = ScientificSource(
    id: 'mattson_2017',
    shortLabel: 'Mattson et al., 2017',
    authors: 'Mattson MP, Longo VD, Harvie M',
    year: 2017,
    title: 'Impact of intermittent fasting on health and disease processes',
    venue: 'Ageing Research Reviews',
    url: 'https://pubmed.ncbi.nlm.nih.gov/27810402/',
    category: SourceCategory.fasting,
    supports: 'Cambio metabólico durante el ayuno y efectos del ayuno '
        'intermitente en la salud.',
    matchTerms: ['mattson'],
  );

  static const sutton2018 = ScientificSource(
    id: 'sutton_2018',
    shortLabel: 'Sutton et al., 2018',
    authors: 'Sutton EF, Beyl R, Early KS, et al.',
    year: 2018,
    title: 'Early Time-Restricted Feeding Improves Insulin Sensitivity, '
        'Blood Pressure, and Oxidative Stress Even without Weight Loss in '
        'Men with Prediabetes',
    venue: 'Cell Metabolism',
    url: 'https://pubmed.ncbi.nlm.nih.gov/29754952/',
    category: SourceCategory.fasting,
    supports: 'Por qué Elena favorece ventanas de alimentación tempranas.',
    matchTerms: ['sutton'],
  );

  static const cahill1966 = ScientificSource(
    id: 'cahill_1966',
    shortLabel: 'Cahill et al., 1966',
    authors: 'Cahill GF Jr, Herrera MG, Morgan AP, et al.',
    year: 1966,
    title: 'Hormone-fuel interrelationships during fasting',
    venue: 'Journal of Clinical Investigation',
    url: 'https://pubmed.ncbi.nlm.nih.gov/5926444/',
    category: SourceCategory.fasting,
    supports: 'El paso de glucosa a grasa como combustible durante el ayuno.',
    matchTerms: ['cahill'],
  );

  static const ohsumi2016 = ScientificSource(
    id: 'ohsumi_2016',
    shortLabel: 'Premio Nobel 2016 — Yoshinori Ohsumi',
    authors: 'Nobel Assembly at Karolinska Institutet',
    year: 2016,
    title: 'The Nobel Prize in Physiology or Medicine 2016: discoveries of '
        'mechanisms for autophagy',
    venue: 'NobelPrize.org',
    url: 'https://www.nobelprize.org/prizes/medicine/2016/summary/',
    category: SourceCategory.fasting,
    supports: 'Qué es la autofagia y por qué se relaciona con el ayuno.',
    matchTerms: ['ohsumi'],
  );

  static const gu2020 = ScientificSource(
    id: 'gu_2020',
    shortLabel: 'Gu et al., 2020',
    authors: 'Gu C, Brereton N, Schweitzer A, et al.',
    year: 2020,
    title: 'Metabolic Effects of Late Dinner in Healthy Volunteers — A '
        'Randomized Crossover Clinical Trial',
    venue: 'Journal of Clinical Endocrinology & Metabolism',
    url: 'https://pubmed.ncbi.nlm.nih.gov/32525525/',
    category: SourceCategory.fasting,
    supports: 'Cenar tarde empeora la glucosa y el uso de grasa durante la '
        'noche.',
    matchTerms: ['gu'],
  );

  static const lopezMinguez2018 = ScientificSource(
    id: 'lopez_minguez_2018',
    shortLabel: 'Lopez-Minguez et al., 2018',
    authors: 'Lopez-Minguez J, Saxena R, Bandín C, Scheer FA, Garaulet M',
    year: 2018,
    title: 'Late dinner impairs glucose tolerance in MTNR1B risk allele '
        'carriers: A randomized, cross-over study',
    venue: 'Clinical Nutrition',
    url: 'https://pubmed.ncbi.nlm.nih.gov/28455106/',
    category: SourceCategory.fasting,
    supports: 'Cenar cerca de la hora de dormir empeora la tolerancia a la '
        'glucosa.',
    matchTerms: ['lopez minguez'],
  );

  // ── Alimentación ────────────────────────────────────────────────────────
  static const jenkins1981 = ScientificSource(
    id: 'jenkins_1981',
    shortLabel: 'Jenkins et al., 1981',
    authors: 'Jenkins DJ, Wolever TM, Taylor RH, et al.',
    year: 1981,
    title: 'Glycemic index of foods: a physiological basis for carbohydrate '
        'exchange',
    venue: 'American Journal of Clinical Nutrition',
    url: 'https://pubmed.ncbi.nlm.nih.gov/6259925/',
    category: SourceCategory.nutrition,
    supports: 'Índice glucémico: base de cómo Elena califica la calidad de '
        'cada plato.',
    matchTerms: ['jenkins'],
  );

  static const jenkins2002 = ScientificSource(
    id: 'jenkins_2002',
    shortLabel: 'Jenkins et al., 2002',
    authors: 'Jenkins DJ, Kendall CW, Augustin LS, et al.',
    year: 2002,
    title: 'Glycemic index: overview of implications in health and disease',
    venue: 'American Journal of Clinical Nutrition',
    url: 'https://pubmed.ncbi.nlm.nih.gov/12081850/',
    category: SourceCategory.nutrition,
    supports: 'Relación entre comidas de bajo índice glucémico, insulina y '
        'riesgo metabólico.',
    matchTerms: ['jenkins'],
  );

  static const liu2000 = ScientificSource(
    id: 'liu_2000',
    shortLabel: 'Liu et al., 2000',
    authors: 'Liu S, Willett WC, Stampfer MJ, et al.',
    year: 2000,
    title: 'A prospective study of dietary glycemic load, carbohydrate '
        'intake, and risk of coronary heart disease in US women',
    venue: 'American Journal of Clinical Nutrition',
    url: 'https://pubmed.ncbi.nlm.nih.gov/10837285/',
    category: SourceCategory.nutrition,
    supports: 'Carga glucémica de la dieta y riesgo cardiovascular.',
    matchTerms: ['liu'],
  );

  static const hall2019 = ScientificSource(
    id: 'hall_2019',
    shortLabel: 'Hall et al., 2019',
    authors: 'Hall KD, Ayuketah A, Brychta R, et al.',
    year: 2019,
    title: 'Ultra-Processed Diets Cause Excess Calorie Intake and Weight '
        'Gain: An Inpatient Randomized Controlled Trial of Ad Libitum Food '
        'Intake',
    venue: 'Cell Metabolism',
    url: 'https://pubmed.ncbi.nlm.nih.gov/31105044/',
    category: SourceCategory.nutrition,
    supports: 'Los ultraprocesados llevan a comer más calorías sin darte '
        'cuenta.',
    matchTerms: ['hall'],
  );

  static const monteiro2019 = ScientificSource(
    id: 'monteiro_2019',
    shortLabel: 'Monteiro et al., 2019',
    authors: 'Monteiro CA, Cannon G, Levy RB, et al.',
    year: 2019,
    title: 'Ultra-processed foods: what they are and how to identify them',
    venue: 'Public Health Nutrition',
    url: 'https://pubmed.ncbi.nlm.nih.gov/30744710/',
    category: SourceCategory.nutrition,
    supports: 'Clasificación NOVA: cómo reconocer un ultraprocesado.',
    matchTerms: ['monteiro', 'nova'],
  );

  static const wolfe2006 = ScientificSource(
    id: 'wolfe_2006',
    shortLabel: 'Wolfe, 2006',
    authors: 'Wolfe RR',
    year: 2006,
    title: 'The underappreciated role of muscle in health and disease',
    venue: 'American Journal of Clinical Nutrition',
    url: 'https://pubmed.ncbi.nlm.nih.gov/16960159/',
    category: SourceCategory.exercise,
    supports: 'El músculo como órgano metabólico: por qué importa '
        'conservarlo.',
    matchTerms: ['wolfe'],
  );

  static const petersen2018 = ScientificSource(
    id: 'petersen_2018',
    shortLabel: 'Petersen & Shulman, 2018',
    authors: 'Petersen MC, Shulman GI',
    year: 2018,
    title: 'Mechanisms of Insulin Action and Insulin Resistance',
    venue: 'Physiological Reviews',
    url: 'https://pubmed.ncbi.nlm.nih.gov/30067154/',
    category: SourceCategory.nutrition,
    supports: 'Cómo funciona la insulina y por qué la grasa visceral empeora '
        'la resistencia a la insulina.',
    matchTerms: ['petersen', 'shulman'],
  );


  // ── Sueño ───────────────────────────────────────────────────────────────
  static const watson2015 = ScientificSource(
    id: 'watson_2015',
    shortLabel: 'AASM / SRS — Watson et al., 2015',
    authors: 'Watson NF, Badr MS, Belenky G, et al.',
    year: 2015,
    title: 'Recommended Amount of Sleep for a Healthy Adult: A Joint '
        'Consensus Statement of the American Academy of Sleep Medicine and '
        'Sleep Research Society',
    venue: 'Sleep',
    url: 'https://pubmed.ncbi.nlm.nih.gov/26039963/',
    category: SourceCategory.sleep,
    supports: 'Recomendación de 7 horas o más de sueño para adultos.',
    matchTerms: ['aasm', 'watson'],
  );

  static const tasali2008 = ScientificSource(
    id: 'tasali_2008',
    shortLabel: 'Tasali et al., 2008',
    authors: 'Tasali E, Leproult R, Ehrmann DA, Van Cauter E',
    year: 2008,
    title: 'Slow-wave sleep and the risk of type 2 diabetes in humans',
    venue: 'PNAS',
    url: 'https://pubmed.ncbi.nlm.nih.gov/18172212/',
    category: SourceCategory.sleep,
    supports: 'El sueño profundo protege la sensibilidad a la insulina.',
    matchTerms: ['tasali'],
  );

  static const spiegel1999 = ScientificSource(
    id: 'spiegel_1999',
    shortLabel: 'Spiegel et al., 1999',
    authors: 'Spiegel K, Leproult R, Van Cauter E',
    year: 1999,
    title: 'Impact of sleep debt on metabolic and endocrine function',
    venue: 'The Lancet',
    url: 'https://pubmed.ncbi.nlm.nih.gov/10543671/',
    category: SourceCategory.sleep,
    supports: 'Dormir poco altera la glucosa y las hormonas del día '
        'siguiente.',
    matchTerms: ['spiegel'],
  );

  static const spiegel2004 = ScientificSource(
    id: 'spiegel_2004',
    shortLabel: 'Spiegel et al., 2004',
    authors: 'Spiegel K, Tasali E, Penev P, Van Cauter E',
    year: 2004,
    title: 'Sleep curtailment in healthy young men is associated with '
        'decreased leptin levels, elevated ghrelin levels, and increased '
        'hunger and appetite',
    venue: 'Annals of Internal Medicine',
    url: 'https://pubmed.ncbi.nlm.nih.gov/15583226/',
    category: SourceCategory.sleep,
    supports: 'Dormir poco sube la grelina, baja la leptina y aumenta el '
        'hambre.',
    matchTerms: ['spiegel'],
  );

  static const ohayon2004 = ScientificSource(
    id: 'ohayon_2004',
    shortLabel: 'Ohayon et al., 2004',
    authors: 'Ohayon MM, Carskadon MA, Guilleminault C, Vitiello MV',
    year: 2004,
    title: 'Meta-analysis of quantitative sleep parameters from childhood to '
        'old age in healthy individuals',
    venue: 'Sleep',
    url: 'https://pubmed.ncbi.nlm.nih.gov/15586779/',
    category: SourceCategory.sleep,
    supports: 'Proporción normal de cada etapa del sueño (ligero, profundo, '
        'REM) según la edad.',
    matchTerms: ['ohayon'],
  );


  static const stamatakis2010 = ScientificSource(
    id: 'stamatakis_2010',
    shortLabel: 'Stamatakis & Punjabi, 2010',
    authors: 'Stamatakis KA, Punjabi NM',
    year: 2010,
    title: 'Effects of sleep fragmentation on glucose metabolism in normal '
        'subjects',
    venue: 'Chest',
    url: 'https://pubmed.ncbi.nlm.nih.gov/19542260/',
    category: SourceCategory.sleep,
    supports: 'Despertarse muchas veces en la noche empeora el manejo de la '
        'glucosa.',
    matchTerms: ['stamatakis', 'punjabi'],
  );

  static const walker2017 = ScientificSource(
    id: 'walker_2017',
    shortLabel: 'Walker, 2017',
    authors: 'Walker M',
    year: 2017,
    title: 'Why We Sleep: Unlocking the Power of Sleep and Dreams',
    venue: 'Scribner (Simon & Schuster)',
    url: 'https://www.simonandschuster.com/books/Why-We-Sleep/'
        'Matthew-Walker/9781501144325',
    category: SourceCategory.sleep,
    supports: 'Divulgación sobre el papel del sueño en la salud y la '
        'recuperación.',
    matchTerms: ['walker'],
  );

  static const drake2013 = ScientificSource(
    id: 'drake_2013',
    shortLabel: 'Drake et al., 2013',
    authors: 'Drake C, Roehrs T, Shambroom J, Roth T',
    year: 2013,
    title: 'Caffeine effects on sleep taken 0, 3, or 6 hours before going to '
        'bed',
    venue: 'Journal of Clinical Sleep Medicine',
    url: 'https://pubmed.ncbi.nlm.nih.gov/24235903/',
    category: SourceCategory.sleep,
    supports: 'La cafeína hasta 6 horas antes de dormir reduce el sueño.',
    matchTerms: ['drake'],
  );

  static const wright2013 = ScientificSource(
    id: 'wright_2013',
    shortLabel: 'Wright et al., 2013',
    authors: 'Wright KP Jr, McHill AW, Birks BR, et al.',
    year: 2013,
    title: 'Entrainment of the human circadian clock to the natural '
        'light-dark cycle',
    venue: 'Current Biology',
    url: 'https://pubmed.ncbi.nlm.nih.gov/23910656/',
    category: SourceCategory.sleep,
    supports: 'La luz natural de la mañana ordena tu reloj biológico.',
    matchTerms: ['wright'],
  );

  static const facerChilds2018 = ScientificSource(
    id: 'facer_childs_2018',
    shortLabel: 'Facer-Childs et al., 2018',
    authors: 'Facer-Childs ER, Boiling S, Balanos GM',
    year: 2018,
    title: 'The effects of time of day and chronotype on cognitive and '
        'physical performance in healthy volunteers',
    venue: 'Sports Medicine — Open',
    url: 'https://pubmed.ncbi.nlm.nih.gov/30357501/',
    category: SourceCategory.exercise,
    supports: 'El rendimiento físico cambia con la hora del día y tu '
        'cronotipo.',
    matchTerms: ['facer childs'],
  );

  // ── Hidratación ─────────────────────────────────────────────────────────
  static const efsa2010 = ScientificSource(
    id: 'efsa_2010',
    shortLabel: 'EFSA, 2010',
    authors: 'EFSA Panel on Dietetic Products, Nutrition, and Allergies',
    year: 2010,
    title: 'Scientific Opinion on Dietary Reference Values for water',
    venue: 'EFSA Journal',
    url: 'https://efsa.onlinelibrary.wiley.com/doi/10.2903/j.efsa.2010.1459',
    category: SourceCategory.hydration,
    supports: 'Cuánta agua necesita un adulto al día.',
    matchTerms: ['efsa'],
  );

  static const popkin2010 = ScientificSource(
    id: 'popkin_2010',
    shortLabel: 'Popkin et al., 2010',
    authors: "Popkin BM, D'Anci KE, Rosenberg IH",
    year: 2010,
    title: 'Water, hydration, and health',
    venue: 'Nutrition Reviews',
    url: 'https://pubmed.ncbi.nlm.nih.gov/20646222/',
    category: SourceCategory.hydration,
    supports: 'Efectos de la hidratación en la energía, el ánimo y el '
        'metabolismo.',
    matchTerms: ['popkin'],
  );

  // ── Ejercicio ───────────────────────────────────────────────────────────
  static const who2020 = ScientificSource(
    id: 'who_2020',
    shortLabel: 'OMS, 2020 — Bull et al.',
    authors: 'Bull FC, Al-Ansari SS, Biddle S, et al.',
    year: 2020,
    title: 'World Health Organization 2020 guidelines on physical activity '
        'and sedentary behaviour',
    venue: 'British Journal of Sports Medicine',
    url: 'https://pubmed.ncbi.nlm.nih.gov/33239350/',
    category: SourceCategory.exercise,
    supports: 'Mínimo de 150 minutos de actividad moderada a la semana.',
    matchTerms: ['oms', 'who', 'bull'],
  );

  static const piercy2018 = ScientificSource(
    id: 'piercy_2018',
    shortLabel: 'Piercy et al., 2018',
    authors: 'Piercy KL, Troiano RP, Ballard RM, et al.',
    year: 2018,
    title: 'The Physical Activity Guidelines for Americans',
    venue: 'JAMA',
    url: 'https://pubmed.ncbi.nlm.nih.gov/30418471/',
    category: SourceCategory.exercise,
    supports: 'Guía oficial de actividad física: aeróbico semanal y fuerza '
        'dos veces por semana.',
    matchTerms: ['piercy'],
  );

  static const acsm2021 = ScientificSource(
    id: 'acsm_2021',
    shortLabel: 'ACSM, 2021',
    authors: 'American College of Sports Medicine; Liguori G (ed.)',
    year: 2021,
    title: "ACSM's Guidelines for Exercise Testing and Prescription, 11.ª ed.",
    venue: 'Wolters Kluwer',
    url: 'https://www.wolterskluwer.com/en/know/acsm/'
        'guidelines-for-exercise-testing-and-prescription',
    category: SourceCategory.exercise,
    supports: 'Dosis diaria de ejercicio y prescripción de fuerza y cardio.',
    matchTerms: ['acsm'],
  );

  // ── Glucosa ─────────────────────────────────────────────────────────────
  static const monnier2017 = ScientificSource(
    id: 'monnier_2017',
    shortLabel: 'Monnier et al., 2017',
    authors: 'Monnier L, Colette C, Wojtusciszyn A, et al.',
    year: 2017,
    title: 'Toward Defining the Threshold Between Low and High Glucose '
        'Variability in Diabetes',
    venue: 'Diabetes Care',
    url: 'https://pubmed.ncbi.nlm.nih.gov/28039172/',
    category: SourceCategory.glucose,
    supports: 'Umbral de 36% de coeficiente de variación para marcar la '
        'variabilidad glucémica como alta.',
    matchTerms: ['monnier'],
  );

  static const adaDiagnosis2025 = ScientificSource(
    id: 'ada_diagnosis_2025',
    shortLabel: 'ADA, 2025 — Diagnóstico y clasificación',
    authors: 'American Diabetes Association Professional Practice Committee',
    year: 2025,
    title: '2. Diagnosis and Classification of Diabetes: Standards of Care '
        'in Diabetes—2025',
    venue: 'Diabetes Care',
    url: 'https://pubmed.ncbi.nlm.nih.gov/39651986/',
    category: SourceCategory.glucose,
    supports: 'Rangos de glucosa: en ayunas menos de 100 mg/dL es normal, de '
        '100 a 125 elevada y 126 o más alta; 2 h después de comer, menos de '
        '140 normal, de 140 a 199 elevada y 200 o más alta.',
    matchTerms: ['ada', 'american diabetes association'],
  );

  static const adaHypoglycemia2025 = ScientificSource(
    id: 'ada_hypoglycemia_2025',
    shortLabel: 'ADA, 2025 — Metas glucémicas e hipoglucemia',
    authors: 'American Diabetes Association Professional Practice Committee',
    year: 2025,
    title: '6. Glycemic Goals and Hypoglycemia: Standards of Care in '
        'Diabetes—2025',
    venue: 'Diabetes Care',
    url: 'https://pubmed.ncbi.nlm.nih.gov/39651981/',
    category: SourceCategory.glucose,
    supports: 'Por debajo de 70 mg/dL se considera glucosa baja '
        '(hipoglucemia nivel 1).',
    matchTerms: ['ada', 'american diabetes association'],
  );

  // ── Hábitos ─────────────────────────────────────────────────────────────
  // 22-nov: Lally 2010 (Eur J Soc Psychol) no está en PubMed y sus copias
  // pasan por controles anti-bots. Se cita el artículo de la misma autora,
  // indexado en PubMed, que resume ese hallazgo para la práctica clínica.
  static const gardner2012 = ScientificSource(
    id: 'gardner_2012',
    shortLabel: 'Gardner, Lally & Wardle, 2012',
    authors: 'Gardner B, Lally P, Wardle J',
    year: 2012,
    title: "Making health habitual: the psychology of 'habit-formation' and "
        'general practice',
    venue: 'British Journal of General Practice',
    url: 'https://pubmed.ncbi.nlm.nih.gov/23211256/',
    category: SourceCategory.habits,
    supports: 'Un hábito tarda semanas en volverse automático: por eso Elena '
        'premia la constancia.',
    matchTerms: ['gardner', 'lally'],
  );

  /// Todas las fuentes, en el orden en que se muestran dentro de cada
  /// categoría.
  static const List<ScientificSource> all = [
    whoBmi,
    navyHodgdon,
    navyShake,
    ashwell2012,
    kouri1995,
    aceBodyFat,
    gallagher2000,
    deCabo2019,
    mattson2017,
    sutton2018,
    cahill1966,
    ohsumi2016,
    gu2020,
    lopezMinguez2018,
    jenkins1981,
    jenkins2002,
    liu2000,
    hall2019,
    monteiro2019,
    petersen2018,
    watson2015,
    tasali2008,
    spiegel1999,
    spiegel2004,
    ohayon2004,
    stamatakis2010,
    walker2017,
    drake2013,
    wright2013,
    efsa2010,
    popkin2010,
    who2020,
    piercy2018,
    acsm2021,
    wolfe2006,
    facerChilds2018,
    adaDiagnosis2025,
    adaHypoglycemia2025,
    monnier2017,
    gardner2012,
  ];

  /// Grupos de fuentes por pantalla de cálculo. Las pantallas piden su
  /// grupo en lugar de repetir listas de ids.
  static const List<ScientificSource> bodyFat = [
    navyHodgdon,
    navyShake,
    aceBodyFat,
    gallagher2000,
  ];

  static const List<ScientificSource> bodyComposition = [
    navyHodgdon,
    navyShake,
    ashwell2012,
    kouri1995,
    aceBodyFat,
  ];

  static const List<ScientificSource> fastingEligibility = [
    whoBmi,
    deCabo2019,
  ];

  static const List<ScientificSource> glucose = [
    adaDiagnosis2025,
    adaHypoglycemia2025,
    monnier2017,
  ];

  /// Un respaldo por pilar del Score del día y del IMR.
  static const List<ScientificSource> fivePillars = [
    sutton2018,
    watson2015,
    efsa2010,
    who2020,
    jenkins2002,
  ];

  static const List<ScientificSource> sleepStages = [
    ohayon2004,
    tasali2008,
    spiegel2004,
    stamatakis2010,
  ];

  /// Etiquetas que viajan en el campo `citation` pero NO son una cita (no
  /// afirman nada respaldado por un estudio). No se convierten en enlace.
  static const Set<String> nonCitationTags = {'basado en tu progreso'};

  /// Términos que NO pueden aparecer como respaldo en texto visible:
  /// marcas comerciales, divulgadores sin revisión por pares o documentos
  /// internos. Una cita así no supera la guía 1.4.1 y, en el caso de
  /// NaturalSlim, además es marca registrada.
  static const List<String> forbiddenCitations = [
    'frank suarez',
    'naturalslim',
    'huberman',
    'biological dial',
    'metabolic clock',
  ];

  static ScientificSource? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Normaliza para comparar: minúsculas, sin tildes, solo letras/dígitos
  /// separados por un espacio.
  static String normalize(String input) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final lower = input.toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static final RegExp _year = RegExp(r'\b(1[89]\d\d|20\d\d)\b');

  /// Separa una cita corta en sus partes independientes:
  /// "Walker 2017 + AASM" → ["Walker 2017", "AASM"].
  /// Las comas y la raya NO separan: "Tasali et al., PNAS 2008" y
  /// "Gu et al., 2020 — JCEM" son una sola cita cada una.
  static List<String> segments(String citation) {
    return citation
        .split(RegExp(r'\s\+\s|\s·\s|^\s*·\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static bool isNonCitation(String citation) =>
      nonCitationTags.contains(normalize(citation));

  /// Fuentes que respaldan UNA parte de la cita.
  ///
  /// Una fuente coincide si alguno de sus [ScientificSource.matchTerms]
  /// aparece como palabra completa y, cuando la parte trae año, el año
  /// coincide. "Spiegel 1999" no se confunde con "Spiegel 2004".
  static List<ScientificSource> resolveSegment(String segment) {
    final norm = ' ${normalize(segment)} ';
    final years =
        _year.allMatches(segment).map((m) => int.parse(m.group(1)!)).toSet();
    final out = <ScientificSource>[];
    for (final s in all) {
      final termHit = s.matchTerms.any((t) => norm.contains(' $t '));
      if (!termHit) continue;
      if (years.isNotEmpty && !years.contains(s.year)) continue;
      out.add(s);
    }
    return out;
  }

  /// Todas las fuentes que respaldan una cita completa, sin repetidos y en
  /// el orden en que aparecen.
  static List<ScientificSource> resolve(String citation) {
    if (isNonCitation(citation)) return const [];
    final out = <ScientificSource>[];
    for (final seg in segments(citation)) {
      for (final s in resolveSegment(seg)) {
        if (!out.contains(s)) out.add(s);
      }
    }
    return out;
  }

  /// Partes de la cita que no resuelven a ninguna fuente. Vacío = cita
  /// completamente verificable.
  static List<String> unresolvedSegments(String citation) {
    if (isNonCitation(citation)) return const [];
    return segments(citation)
        .where((seg) => resolveSegment(seg).isEmpty)
        .toList();
  }

  /// True si la cita menciona un respaldo prohibido.
  static bool mentionsForbidden(String text) {
    final norm = ' ${normalize(text)} ';
    return forbiddenCitations.any((f) => norm.contains(' $f '));
  }
}
