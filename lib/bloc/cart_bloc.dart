import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._api) : super(const CartState()) {
    on<CartProductAdded>(
        (e, emit) => _apply(e, emit, state.copyWith(lines: state.lines.withProduct(e.product))));
    on<CartProductRemoved>(
        (e, emit) => _apply(e, emit, state.copyWith(lines: state.lines.without(e.productId))));
    on<CartQtyChanged>((e, emit) =>
        _apply(e, emit, state.copyWith(lines: state.lines.changeQty(e.productId, e.delta))));
    on<CartCouponApplied>((e, emit) => _apply(e, emit, state.withCoupon(e.code)));
    on<CartUndone>(_onUndone);
    // droppable(): taps that arrive while a checkout is running are ignored.
    on<CartCheckoutRequested>(_onCheckout, transformer: droppable());
  }

  final CheckoutApi _api;
  final _history = <CartState>[];

  void _apply(CartEvent event, Emitter<CartState> emit, CartState next) {
    if (next == state) return;
    if (isUndoable(event)) _history.add(state);
    emit(next.copyWith(canUndo: _history.isNotEmpty));
  }

  void _onUndone(CartUndone event, Emitter<CartState> emit) {
    if (_history.isEmpty) return;
    final prev = _history.removeLast();
    emit(state.copyWith(
      lines: prev.lines,
      coupon: prev.coupon,
      couponError: prev.couponError,
      canUndo: _history.isNotEmpty,
    ));
  }

  Future<void> _onCheckout(CartCheckoutRequested event, Emitter<CartState> emit) async {
    if (state.lines.isEmpty) return;
    final total = state.total;
    emit(state.copyWith(status: CheckoutStatus.submitting, checkoutError: null));
    try {
      final id = await _api.submit(total);
      if (emit.isDone) return; // bloc closed while we were awaiting
      _history.clear();
      emit(const CartState().copyWith(status: CheckoutStatus.success, orderId: id));
    } on CheckoutException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message));
    }
  }
}
