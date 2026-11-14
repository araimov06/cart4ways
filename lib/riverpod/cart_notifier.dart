import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => const CheckoutApi());

class CartNotifier extends Notifier<CartState> {
  final _history = <CartState>[]; // T5: lives and dies with this notifier instance

  @override
  CartState build() => const CartState();

  bool get canUndo => _history.isNotEmpty;

  void _commit(CartState next) {
    if (next == state) return; // equal state would not notify anyway
    _history.add(state);
    state = next;
  }

  void add(Product p) => _commit(state.copyWith(lines: state.lines.withProduct(p)));
  void changeQty(String id, int delta) =>
      _commit(state.copyWith(lines: state.lines.changeQty(id, delta)));
  void applyCoupon(String code) => _commit(state.withCoupon(code));

  void undo() {
    if (_history.isEmpty) return;
    final prev = _history.removeLast();
    state = state.copyWith(lines: prev.lines, coupon: prev.coupon, couponError: prev.couponError);
  }

  Future<void> checkout() async {
    if (state.status == CheckoutStatus.submitting) return;
    final total = state.total;
    state = state.copyWith(status: CheckoutStatus.submitting, checkoutError: null);
    try {
      // No `mounted` check: the notifier lives in the ProviderContainer, not in a widget.
      final id = await ref.read(checkoutApiProvider).submit(total);
      _history.clear();
      state = const CartState().copyWith(status: CheckoutStatus.success, orderId: id);
    } on CheckoutException catch (e) {
      state = state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message);
    }
  }
}

// T5 experiment: swap for `NotifierProvider.autoDispose<CartNotifier, CartState>(CartNotifier.new)`,
// pop the page and come back: a NEW notifier is built, so state AND _history are gone.
final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// A getter on the notifier is not observable, so watch the state (it changes on every
/// mutation) and re-read the getter.
final canUndoProvider = Provider<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});
