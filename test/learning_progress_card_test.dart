import 'package:coinwise/widgets/learning_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the next module and progress from completed modules',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningProgressCard(
            completedCount: 2,
            totalModules: 5,
            nextModuleLabel: 'Modul 3/5 • Wallet dan keamanan',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('2/5 modul selesai'), findsOneWidget);
    expect(find.text('Modul 3/5 • Wallet dan keamanan'), findsOneWidget);
    expect(find.text('40% selesai'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.4);

    await tester.tap(find.text('Lanjutkan Belajar'));
    expect(tapped, isTrue);
  });

  testWidgets('shows complete progress when every module is finished',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningProgressCard(
            completedCount: 5,
            totalModules: 5,
            nextModuleLabel: 'Semua modul selesai',
            onTap: _noop,
          ),
        ),
      ),
    );

    expect(find.text('5/5 modul selesai'), findsOneWidget);
    expect(find.text('Semua modul selesai'), findsOneWidget);
    expect(find.text('100% selesai'), findsOneWidget);
  });
}

void _noop() {}
