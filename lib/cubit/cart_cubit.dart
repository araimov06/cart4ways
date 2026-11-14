import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());
  final CheckoutApi _api;
  final _history = <CartState>[];

  void _commit(CartState next) {
    if (next == state) return; // emit would drop it anyway; also keeps history clean
    _history.add(state);
    // canUndo is folded into the state: a getter on the cubit is not observable.
    emit(next.copyWith(canUndo: true));
  }

  void add(Product p) => _commit(state.copyWith(lines: state.lines.withProduct(p)));
  void changeQty(String id, int delta) =>
      _commit(state.copyWith(lines: state.lines.changeQty(id, delta)));
  void applyCoupon(String code) => _commit(state.withCoupon(code));

  void undo() {
    if (_history.isEmpty) return;
    final prev = _history.removeLast();
    emit(state.copyWith(
      lines: prev.lines,
      coupon: prev.coupon,
      couponError: prev.couponError,
      canUndo: _history.isNotEmpty,
    ));
  }

  Future<void> checkout() async {
    if (state.status == CheckoutStatus.submitting) return;
    final total = state.total;
    emit(state.copyWith(status: CheckoutStatus.submitting, checkoutError: null));
    try {
      final id = await _api.submit(total);
      if (isClosed) return; // emit after close() throws
      _history.clear();
      emit(const CartState().copyWith(status: CheckoutStatus.success, orderId: id));
    } on CheckoutException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message));
    }
  }
}
