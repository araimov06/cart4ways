import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  setUpAll(() => registerFallbackValue(0.0));

  test('two keyboards + SAVE10 => total 88.2', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(cartProvider.notifier);

    cart.add(catalog.first);
    cart.add(catalog.first);
    cart.applyCoupon('SAVE10');

    expect(container.read(cartProvider).total, closeTo(88.2, 0.001));
  });

  test('failed checkout sets failure and keeps the lines', () async {
    final api = MockCheckoutApi();
    when(() => api.submit(any()))
        .thenAnswer((_) async => throw const CheckoutException('Card declined'));
    final container = ProviderContainer(overrides: [checkoutApiProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
    final cart = container.read(cartProvider.notifier);

    cart.add(catalog.first);
    await cart.checkout();

    final s = container.read(cartProvider);
    expect(s.status, CheckoutStatus.failure);
    expect(s.checkoutError, 'Card declined');
    expect(s.lines, isNotEmpty);
  });
}
