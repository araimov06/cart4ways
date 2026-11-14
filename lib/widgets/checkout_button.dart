import 'package:flutter/material.dart';

class CheckoutButton extends StatelessWidget {
  const CheckoutButton({
    super.key,
    required this.submitting,
    required this.enabled,
    required this.onPressed,
  });
  final bool submitting;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('checkout'),
            onPressed: enabled && !submitting ? onPressed : null,
            child: submitting
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Checkout'),
          ),
        ),
      );
}
