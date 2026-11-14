import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/checkout_button.dart';
import '../widgets/checkout_feedback.dart';
import '../widgets/summary_card.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartBloc(const CheckoutApi()),
        child: const _BlocCartView(),
      );
}

class _BlocCartView extends StatelessWidget {
  const _BlocCartView();

  @override
  Widget build(BuildContext context) => BlocListener<CartBloc, CartState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) => showCheckoutFeedback(context, state),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Cart · Bloc'),
            actions: [
              BlocBuilder<CartBloc, CartState>(
                buildWhen: (p, c) => p.canUndo != c.canUndo,
                builder: (context, s) => IconButton(
                  key: const Key('undo'),
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                  onPressed: s.canUndo ? () => context.read<CartBloc>().add(const CartUndone()) : null,
                ),
              ),
            ],
          ),
          body: BlocBuilder<CartBloc, CartState>(
            buildWhen: (p, c) => p.lines != c.lines || p.couponError != c.couponError,
            builder: (context, s) {
              final bloc = context.read<CartBloc>();
              return CartBody(
                lines: s.lines,
                couponError: s.couponError,
                onAdd: (p) => bloc.add(CartProductAdded(p)),
                onQtyChanged: (id, d) => bloc.add(CartQtyChanged(id, d)),
                onApplyCoupon: (code) => bloc.add(CartCouponApplied(code)),
                summary: const _Summary(),
                checkout: const _Checkout(),
              );
            },
          ),
        ),
      );
}

class _Summary extends StatelessWidget {
  const _Summary();
  @override
  Widget build(BuildContext context) =>
      BlocSelector<CartBloc, CartState, CartSummary>(
        selector: (s) => s.summary,
        builder: (context, summary) {
          debugPrint('[bloc] SummaryCard rebuilt');
          return SummaryCard(summary: summary);
        },
      );
}

class _Checkout extends StatelessWidget {
  const _Checkout();
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CartBloc, CartState>(
        buildWhen: (p, c) => p.status != c.status || p.lines.isEmpty != c.lines.isEmpty,
        builder: (context, s) => CheckoutButton(
          submitting: s.status == CheckoutStatus.submitting,
          enabled: s.lines.isNotEmpty,
          onPressed: () => context.read<CartBloc>().add(const CartCheckoutRequested()),
        ),
      );
}
