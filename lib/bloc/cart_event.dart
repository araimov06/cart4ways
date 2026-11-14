import '../models/cart.dart';

sealed class CartEvent {
  const CartEvent();
}

final class CartProductAdded extends CartEvent {
  const CartProductAdded(this.product);
  final Product product;
}

final class CartProductRemoved extends CartEvent {
  const CartProductRemoved(this.productId);
  final String productId;
}

final class CartQtyChanged extends CartEvent {
  const CartQtyChanged(this.productId, this.delta);
  final String productId;
  final int delta;
}

final class CartCouponApplied extends CartEvent {
  const CartCouponApplied(this.code);
  final String code;
}

final class CartCheckoutRequested extends CartEvent {
  const CartCheckoutRequested();
}

final class CartUndone extends CartEvent {
  const CartUndone();
}

/// T5 decision: which events push onto the undo history?
/// Cart edits are undoable. Checkout is a side effect with a server round-trip and
/// Undo itself must not be recorded. The exhaustive switch forces a decision for any new event.
bool isUndoable(CartEvent e) => switch (e) {
      CartProductAdded() ||
      CartProductRemoved() ||
      CartQtyChanged() ||
      CartCouponApplied() =>
        true,
      CartCheckoutRequested() || CartUndone() => false,
    };
