// SPEC-205 inc4: widget test del quiz.

import 'package:elena_app/src/features/content/domain/post.dart';
import 'package:elena_app/src/features/content/presentation/post_quiz_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _questions = [
  QuizQuestion(
    question: '¿Pregunta 1?',
    options: ['Opción A', 'Opción B correcta'],
    correctIndex: 1,
  ),
];

Widget _wrap() => const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PostQuizView(questions: _questions, accent: Colors.indigo),
        ),
      ),
    );

void main() {
  testWidgets('muestra el título y el contador', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Pon a prueba lo que aprendiste'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);
  });

  testWidgets('acierto → check + resumen perfecto', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Opción B correcta'));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    expect(find.textContaining('¡Perfecto!'), findsOneWidget);
  });

  testWidgets('error → marca incorrecta y revela la correcta', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Opción A'));
    await tester.pump();

    expect(find.byIcon(Icons.cancel), findsOneWidget); // la elegida (mal)
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // revela correcta
    expect(find.textContaining('Acertaste 0 de 1'), findsOneWidget);
  });
}
