import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/checkout_button.dart';
import '../widgets/checkout_feedback.dart';
import '../widgets/summary_card.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartCubit(const CheckoutApi()), // scoped to this page, closed on dispose
        child: const _CubitCartView(),
      );
}

// Separate widget so its context is BELOW the BlocProvider (context.read needs that).
class _CubitCartView extends StatelessWidget {
  const _CubitCartView();

  @override
  Widget build(BuildContext context) => BlocListener<CartCubit, CartState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) => showCheckoutFeedback(context, state),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Cart · Cubit'),
            actions: [
              BlocBuilder<CartCubit, CartState>(
                buildWhen: (p, c) => p.canUndo != c.canUndo,
                builder: (context, s) => IconButton(
                  key: const Key('undo'),
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                  onPressed: s.canUndo ? context.read<CartCubit>().undo : null,
                ),
              ),
            ],
          ),
          body: BlocBuilder<CartCubit, CartState>(
            buildWhen: (p, c) => p.lines != c.lines || p.couponError != c.couponError,
            builder: (context, s) {
              final cubit = context.read<CartCubit>();
              return CartBody(
                lines: s.lines,
                couponError: s.couponError,
                onAdd: cubit.add,
                onQtyChanged: cubit.changeQty,
                onApplyCoupon: cubit.applyCoupon,
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
      BlocSelector<CartCubit, CartState, CartSummary>(
        selector: (s) => s.summary,
        builder: (context, summary) {
          debugPrint('[cubit] SummaryCard rebuilt');
          return SummaryCard(summary: summary);
        },
      );
}

class _Checkout extends StatelessWidget {
  const _Checkout();
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CartCubit, CartState>(
        buildWhen: (p, c) => p.status != c.status || p.lines.isEmpty != c.lines.isEmpty,
        builder: (context, s) => CheckoutButton(
          submitting: s.status == CheckoutStatus.submitting,
          enabled: s.lines.isNotEmpty,
          onPressed: context.read<CartCubit>().checkout,
        ),
      );
}
