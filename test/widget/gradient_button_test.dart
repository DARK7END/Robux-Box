import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robux_box/core/widgets/gradient_button.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('renders label and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(GradientButton(
      label: 'Watch ad',
      onPressed: () => taps++,
    )));

    expect(find.text('Watch ad'), findsOneWidget);
    await tester.tap(find.byType(GradientButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('does not fire when loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(GradientButton(
      label: 'Redeem',
      loading: true,
      onPressed: () => taps++,
    )));

    // Loading replaces the label with a spinner.
    expect(find.text('Redeem'), findsNothing);
    await tester.tap(find.byType(GradientButton));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('does not fire when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(GradientButton(
      label: 'Locked',
      enabled: false,
      onPressed: () => taps++,
    )));
    await tester.tap(find.byType(GradientButton));
    await tester.pump();
    expect(taps, 0);
  });
}
