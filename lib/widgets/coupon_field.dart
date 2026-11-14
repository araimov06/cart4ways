import 'package:flutter/material.dart';

class CouponField extends StatefulWidget {
  const CouponField({super.key, required this.error, required this.onApply});
  final String? error;
  final void Function(String code) onApply;

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextField(
              key: const Key('couponField'),
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Coupon code',
                isDense: true,
                errorText: widget.error,
                errorStyle: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: const Key('applyCoupon'),
            onPressed: () => widget.onApply(_controller.text),
            child: const Text('Apply'),
          ),
        ]),
      );
}
