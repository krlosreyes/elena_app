// SPEC-200: punto de una serie de puntaje día a día (0-100) para el chart
// de tendencia genérico. Reusado por IMR longitudinal y por el Score del Día.
//
// `date` en formato 'yyyy-MM-dd' (orden lexicográfico = cronológico).
typedef ScoreTrendPoint = ({String date, int value});
