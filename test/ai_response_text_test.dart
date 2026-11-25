import 'package:coinwise/widgets/ai_response_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Markdown emphasis and lists without raw markers',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiResponseText(
            text: 'Kripto adalah **aset digital**.\n\n- Bitcoin\n- Ethereum',
          ),
        ),
      ),
    );

    final renderedText = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((widget) => widget.text.toPlainText())
        .join('\n');

    expect(renderedText, contains('aset digital'));
    expect(renderedText, contains('Bitcoin'));
    expect(renderedText, contains('Ethereum'));
    expect(renderedText, isNot(contains('**')));
  });
}
