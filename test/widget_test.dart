import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_english/main.dart';

void main() {
  testWidgets('EasyEnglishApp renders Duolingo-style welcome screen and navigates to home',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EasyEnglishApp(),
      ),
    );

    // Verify Welcome header is present
    expect(find.text('Welcome to EasyEnglish!'), findsOneWidget);
    expect(find.text('CHOOSE YOUR REGION'), findsOneWidget);

    // Verify India is displayed in region list
    expect(find.text('India'), findsOneWidget);
    expect(find.text('1420 learners online right now'), findsOneWidget);

    // Tap Continue to Practice
    await tester.tap(find.text('CONTINUE TO PRACTICE'));
    await tester.pumpAndSettle();

    // Verify Home Screen with pure audio room is displayed
    expect(find.text('EasyEnglish'), findsOneWidget);
    expect(find.text('Live 1-on-1 Audio Room'), findsOneWidget);
    expect(find.text('Gemini 2.5 AI Coach'), findsOneWidget);
  });
}
