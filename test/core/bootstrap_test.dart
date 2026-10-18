import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_platform/src/core/config/bootstrap_app.dart';

void main() {
  testWidgets('startup error hides details and can recover on retry', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      BootstrapApp(
        initialize: () async {
          if (++attempts == 1) throw StateError('private backend details');
          return const MaterialApp(home: Text('Ready'));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('private backend'), findsNothing);
    expect(attempts, 1);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(attempts, 2);
  });
}
