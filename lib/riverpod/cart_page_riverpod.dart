import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../widgets/cart_body.dart';
import '../widgets/checkout_button.dart';
import '../widgets/checkout_feedback.dart';
import '../widgets/summary_card.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerWidget {
  const RiverpodCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // T2 demo: only fires when the new state is != the old one (== override on CartState).
    ref.listen<CartState>(cartProvider, (prev, next) => debugPrint('[riverpod] $next'));

    // T4: side effects live in listen, never in build.
    ref.listen(cartProvider.select((s) => s.status), (prev, next) {
      showCheckoutFeedback(context, ref.read(cartProvider));
    });

    final view = ref.watch(cartProvider.select((s) => (lines: s.lines, couponError: s.couponError)));
    final cart = ref.read(cartProvider.notifier); // handle only, no subscription

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: const [_UndoButton()],
      ),
      body: CartBody(
        lines: view.lines,
        couponError: view.couponError,
        onAdd: cart.add,
        onQtyChanged: cart.changeQty,
        onApplyCoupon: cart.applyCoupon,
        summary: const _Summary(),
        checkout: const _CheckoutButton(),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[riverpod] SummaryCard rebuilt');
    final summary = ref.watch(cartProvider.select((s) => s.summary));
    return SummaryCard(summary: summary);
  }
}

class _UndoButton extends ConsumerWidget {
  const _UndoButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        key: const Key('undo'),
        icon: const Icon(Icons.undo),
        tooltip: 'Undo',
        onPressed: ref.watch(canUndoProvider) ? ref.read(cartProvider.notifier).undo : null,
      );
}

class _CheckoutButton extends ConsumerWidget {
  const _CheckoutButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(cartProvider.select(
        (s) => (submitting: s.status == CheckoutStatus.submitting, enabled: s.lines.isNotEmpty)));
    return CheckoutButton(
      submitting: v.submitting,
      enabled: v.enabled,
      onPressed: ref.read(cartProvider.notifier).checkout,
    );
  }
}
