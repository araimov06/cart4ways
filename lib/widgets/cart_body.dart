import 'package:flutter/material.dart';
import '../models/cart.dart';
import 'coupon_field.dart';

/// Dumb UI shared by all four styles: data + callbacks, no state management.
class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.couponError,
    required this.onAdd,
    required this.onQtyChanged,
    required this.onApplyCoupon,
    required this.summary,
    required this.checkout,
  });

  final List<CartLine> lines;
  final String? couponError;
  final void Function(Product) onAdd;
  final void Function(String productId, int delta) onQtyChanged;
  final void Function(String code) onApplyCoupon;

  /// Slots, so each style can plug in its own selectively-rebuilding widgets.
  final Widget summary;
  final Widget checkout;

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 8, children: [
            for (final p in catalog)
              ActionChip(
                label: Text('${p.name} · ${p.price.toStringAsFixed(0)}'),
                onPressed: () => onAdd(p),
              ),
          ]),
        ),
        Expanded(
          child: lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(children: [
                  for (final l in lines)
                    ListTile(
                      key: ValueKey(l.product.id),
                      title: Text(l.product.name),
                      subtitle: Text('× ${l.qty}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          key: Key('dec-${l.product.id}'),
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => onQtyChanged(l.product.id, -1),
                        ),
                        IconButton(
                          key: Key('inc-${l.product.id}'),
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => onQtyChanged(l.product.id, 1),
                        ),
                      ]),
                    ),
                ]),
        ),
        CouponField(error: couponError, onApply: onApplyCoupon),
        summary,
        checkout,
      ]);
}
