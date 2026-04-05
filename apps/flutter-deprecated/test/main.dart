import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platforms_app_flutter/Main.dart';

void main() {
  testWidgets('Station button shows list of stations', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(PlatformsApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.edit_location));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('Waterloo'), findsOneWidget);
  });
}
