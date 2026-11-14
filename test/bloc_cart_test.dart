import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  late MockCheckoutApi api;
  final seeded = CartState(lines: [CartLine(product: catalog.first, qty: 1)]);

  setUpAll(() => registerFallbackValue(0.0));
  setUp(() => api = MockCheckoutApi());

  blocTest<CartBloc, CartState>(
    'add, add, SAVE10 emits three states',
    build: () => CartBloc(api),
    act: (b) => b
      ..add(CartProductAdded(catalog.first))
      ..add(CartProductAdded(catalog.first))
      ..add(const CartCouponApplied('SAVE10')),
    expect: () => [
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 1),
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 2),
      isA<CartState>().having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartBloc, CartState>(
    'failing checkout emits submitting then failure',
    build: () {
      when(() => api.submit(any()))
          .thenAnswer((_) async => throw const CheckoutException('Card declined'));
      return CartBloc(api);
    },
    seed: () => seeded,
    act: (b) => b.add(const CartCheckoutRequested()),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.failure),
    ],
  );

  blocTest<CartBloc, CartState>(
    'droppable: two checkout requests submit only once',
    build: () {
      when(() => api.submit(any()))
          .thenAnswer((_) => Future.delayed(const Duration(milliseconds: 50), () => 'ORD-1'));
      return CartBloc(api);
    },
    seed: () => seeded,
    act: (b) => b
      ..add(const CartCheckoutRequested())
      ..add(const CartCheckoutRequested()),
    wait: const Duration(milliseconds: 150),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.success),
    ],
    verify: (_) => verify(() => api.submit(any())).called(1),
  );
}
