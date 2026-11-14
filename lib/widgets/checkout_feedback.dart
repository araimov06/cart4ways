import 'package:flutter/material.dart';
import '../models/cart.dart';

/// Side effect shared by all styles: SnackBar on success, MaterialBanner on failure.
/// Call it from a listener (never from build).
void showCheckoutFeedback(BuildContext context, CartState s) {
  final m = ScaffoldMessenger.of(context);
  switch (s.status) {
    case CheckoutStatus.submitting:
      m.hideCurrentMaterialBanner();
    case CheckoutStatus.success:
      m.hideCurrentMaterialBanner();
      m.showSnackBar(SnackBar(content: Text('Order ${s.orderId} placed')));
    case CheckoutStatus.failure:
      m.hideCurrentMaterialBanner();
      m.showMaterialBanner(MaterialBanner(
        content: Text(s.checkoutError ?? 'Checkout failed'),
        actions: [TextButton(onPressed: m.hideCurrentMaterialBanner, child: const Text('Dismiss'))],
      ));
    case CheckoutStatus.idle:
      break;
  }
}
