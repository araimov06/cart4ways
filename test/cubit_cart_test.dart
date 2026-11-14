import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  late MockCheckoutApi api;
  setUpAll(() => registerFallbackValue(0.0));
  setUp(() => api = MockCheckoutApi());

  blocTest<CartCubit, CartState>(
    'add, add, SAVE10 emits three states',
    build: () => CartCubit(api),
    act: (c) {
      c.add(catalog.first);
      c.add(catalog.first);
      c.applyCoupon('SAVE10');
    },
    expect: () => [
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 1),
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 2),
      isA<CartState>().having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartCubit, CartState>(
    'failing checkout emits submitting then failure',
    build: () {
      when(() => api.submit(any()))
          .thenAnswer((_) async => throw const CheckoutException('Card declined'));
      return CartCubit(api);
    },
    seed: () => CartState(lines: [CartLine(product: catalog.first, qty: 1)]),
    act: (c) => c.checkout(),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.failure),
    ],
  );
}
