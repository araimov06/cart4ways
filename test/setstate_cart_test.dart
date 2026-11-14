import 'package:cart_four_ways/setstate/cart_page_setstate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('two keyboards + SAVE10 => total 88.20', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SetStateCartPage()));

    await tester.tap(find.text('Keyboard · 49'));
    await tester.pump();
    await tester.tap(find.text('Keyboard · 49'));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('couponField')), 'SAVE10');
    await tester.tap(find.byKey(const Key('applyCoupon')));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('total'))).data, '88.20');
  });
}
