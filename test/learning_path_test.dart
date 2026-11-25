import 'package:coinwise/screens/learn_screen.dart';
import 'package:coinwise/screens/learning_module_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('wrong quiz answers show an explanation and can be retried',
      (tester) async {
    var completed = false;
    final module = learningModules.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => LearningModuleScreen(
                    module: module,
                    moduleNumber: 1,
                    totalModules: learningModules.length,
                    onComplete: () async {
                      completed = true;
                      return true;
                    },
                  ),
                ),
              ),
              child: const Text('Buka modul'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka modul'));
    await tester.pumpAndSettle();

    final question = module.questions.first;
    final wrongIndex = (question.correctIndex + 1) % question.options.length;
    await tester.scrollUntilVisible(
      find.text(question.options[wrongIndex]),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(question.options[wrongIndex]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(question.options[wrongIndex]));
    await tester.pumpAndSettle();

    expect(find.text('Belum tepat'), findsOneWidget);
    expect(find.text(question.explanation), findsOneWidget);
    expect(completed, isFalse);

    await tester.scrollUntilVisible(
      find.text('Coba lagi'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum tepat'), findsNothing);
  });

  testWidgets('modules unlock in order and progress persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: LearnScreen()));
    await tester.pumpAndSettle();

    final firstModule = learningModules.first;
    final secondModule = learningModules[1];
    expect(
      find.text('Selesaikan modul sebelumnya untuk membuka'),
      findsNWidgets(learningModules.length - 1),
    );

    await tester.ensureVisible(find.text('Modul 1 • ${firstModule.title}'));
    await tester.tap(find.text('Modul 1 • ${firstModule.title}'));
    await tester.pumpAndSettle();

    for (var index = 0; index < firstModule.questions.length; index++) {
      final question = firstModule.questions[index];
      await tester.scrollUntilVisible(
        find.text(question.question),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.text(question.options[question.correctIndex]),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(question.options[question.correctIndex]));
      await tester.pumpAndSettle();

      final action = index == firstModule.questions.length - 1
          ? 'Selesaikan modul'
          : 'Pertanyaan berikutnya';
      await tester.scrollUntilVisible(
        find.text(action),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
    }

    expect(find.text('1 dari ${learningModules.length} modul selesai'),
        findsOneWidget);
    expect(find.text('Selesaikan modul sebelumnya untuk membuka'),
        findsNWidgets(learningModules.length - 2));
    expect(find.text('Materi dan kuis singkat'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('completed_learning_modules_guest'),
      contains(firstModule.id),
    );

    await tester.ensureVisible(find.text('Modul 2 • ${secondModule.title}'));
    await tester.tap(find.text('Modul 2 • ${secondModule.title}'));
    await tester.pumpAndSettle();
    expect(find.byType(LearningModuleScreen), findsOneWidget);
  });
}
