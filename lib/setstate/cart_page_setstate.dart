import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/checkout_button.dart';
import '../widgets/checkout_feedback.dart';
import '../widgets/summary_card.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key, this.api = const CheckoutApi()});
  final CheckoutApi api;

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  CartState _state = const CartState(); // state is a field on the State object
  final List<CartState> _history = []; // T5: dies with this State object

  /// Every undoable mutation goes through here (not checkout status changes).
  void _commit(CartState next) {
    if (next == _state) return;
    setState(() {
      _history.add(_state);
      _state = next;
    });
  }

  void _add(Product p) => _commit(_state.copyWith(lines: _state.lines.withProduct(p)));
  void _changeQty(String id, int delta) =>
      _commit(_state.copyWith(lines: _state.lines.changeQty(id, delta)));
  void _applyCoupon(String code) => _commit(_state.withCoupon(code));

  void _undo() {
    final prev = _history.removeLast();
    setState(() {
      _state = _state.copyWith(
        lines: prev.lines,
        coupon: prev.coupon,
        couponError: prev.couponError,
      );
    });
  }

  Future<void> _checkout() async {
    if (_state.status == CheckoutStatus.submitting) return;
    final total = _state.total;
    setState(() => _state = _state.copyWith(status: CheckoutStatus.submitting, checkoutError: null));
    try {
      final id = await widget.api.submit(total);
      // Without this, setState/context below would run on a disposed State.
      if (!mounted) return;
      setState(() {
        _history.clear();
        _state = const CartState().copyWith(status: CheckoutStatus.success, orderId: id);
      });
      showCheckoutFeedback(context, _state);
    } on CheckoutException catch (e) {
      if (!mounted) return;
      setState(() => _state =
          _state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message));
      showCheckoutFeedback(context, _state);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Cart · setState'),
          actions: [
            IconButton(
              key: const Key('undo'),
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: _history.isEmpty ? null : _undo,
            ),
          ],
        ),
        body: CartBody(
          lines: _state.lines,
          couponError: _state.couponError,
          onAdd: _add,
          onQtyChanged: _changeQty,
          onApplyCoupon: _applyCoupon,
          summary: SummaryCard(summary: _state.summary),
          checkout: CheckoutButton(
            submitting: _state.status == CheckoutStatus.submitting,
            enabled: _state.lines.isNotEmpty,
            onPressed: _checkout,
          ),
        ),
      );
}
