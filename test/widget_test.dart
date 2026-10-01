import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_english/main.dart';

void main() {
  testWidgets('EasyEnglishApp smoke test renders home screen with action cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EasyEnglishApp(),
      ),
    );

    // Verify EasyEnglish title is present
    expect(find.text('EasyEnglish'), findsOneWidget);

    // Verify Free and Pro action cards are rendered
    expect(find.text('1-on-1 Peer Matchmaking'), findsOneWidget);
    expect(find.text('Gemini AI Speaking Coach'), findsOneWidget);
  });
}
