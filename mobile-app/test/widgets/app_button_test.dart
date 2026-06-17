import 'package:akuko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('AppButton shows label and fires onPressed', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _wrap(
        AppButton(label: 'Read', onPressed: () => tapped++),
      ),
    );

    expect(find.text('Read'), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('AppButton shows spinner and disables tap while loading',
      (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _wrap(
        AppButton(label: 'Read', isLoading: true, onPressed: () => tapped++),
      ),
    );

    expect(find.text('Read'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(tapped, 0);
  });
}
