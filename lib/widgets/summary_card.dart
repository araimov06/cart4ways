import 'package:flutter/material.dart';
import '../models/cart.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});
  final CartSummary summary;

  Widget _row(String label, String value, {Key? key, bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: style),
      Text(value, key: key, style: style),
    ]);
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _row('Items', '${summary.itemCount}'),
            _row('Subtotal', summary.subtotal.toStringAsFixed(2)),
            _row('Discount', '-${summary.discount.toStringAsFixed(2)}'),
            _row('Total', summary.total.toStringAsFixed(2), key: const Key('total'), bold: true),
          ]),
        ),
      );
}
