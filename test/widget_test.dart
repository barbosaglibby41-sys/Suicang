import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suicang/app/suicang_app.dart';

void main() {
  testWidgets('Suicang opens the discover screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SuicangApp()));
    await tester.pumpAndSettle();

    expect(find.text('suicang'), findsOneWidget);
    expect(find.text('继续对话'), findsOneWidget);
    expect(find.textContaining('想让谁走进你的故事'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('对话'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Luna'), findsWidgets);
    expect(find.textContaining('写下你的回复'), findsOneWidget);
  });
}
