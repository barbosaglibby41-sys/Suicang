import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suicang/app/suicang_app.dart';

void main() {
  testWidgets('Suicang opens the discover screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SuicangApp()));
    await tester.pumpAndSettle();

    expect(find.text('Suicang'), findsOneWidget);
    expect(find.text('快速开始'), findsOneWidget);
    expect(find.textContaining('让灵感'), findsOneWidget);

    await tester.tap(find.text('聊天'));
    await tester.pumpAndSettle();
    expect(find.text('Luna'), findsOneWidget);
    expect(find.textContaining('写下你的回复'), findsOneWidget);
  });
}
