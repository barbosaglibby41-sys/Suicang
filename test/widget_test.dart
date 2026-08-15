import 'package:flutter_test/flutter_test.dart';
import 'package:suicang/app/suicang_app.dart';

void main() {
  testWidgets('Suicang opens the discover screen', (tester) async {
    await tester.pumpWidget(const SuicangApp());
    await tester.pumpAndSettle();

    expect(find.text('Suicang'), findsOneWidget);
    expect(find.text('快速开始'), findsOneWidget);
    expect(find.text('继续对话'), findsOneWidget);
  });
}
