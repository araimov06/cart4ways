import 'package:flutter/foundation.dart';

const kCouponCode = 'SAVE10';
const kCouponRate = 0.10;

class Product {
  const Product({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;

  @override
  bool operator ==(Object other) =>
      other is Product && other.id == id && other.name == name && other.price == price;
  @override
  int get hashCode => Object.hash(id, name, price);
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({required this.product, required this.qty});
  final Product product;
  final int qty;

  double get subtotal => product.price * qty;
  CartLine copyWith({int? qty}) => CartLine(product: product, qty: qty ?? this.qty);

  @override
  bool operator ==(Object other) =>
      other is CartLine && other.product == product && other.qty == qty;
  @override
  int get hashCode => Object.hash(product, qty);
}

/// Pure, style-independent cart logic. Every state holder calls these.
extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) return [...this, CartLine(product: p, qty: 1)];
    return [for (final l in this) l.product.id == p.id ? l.copyWith(qty: l.qty + 1) : l];
  }

  List<CartLine> without(String productId) =>
      [for (final l in this) if (l.product.id != productId) l];

  /// T1: +1 / -1. A line whose qty would drop to 0 is removed.
  List<CartLine> changeQty(String productId, int delta) => [
        for (final l in this)
          if (l.product.id != productId)
            l
          else if (l.qty + delta > 0)
            l.copyWith(qty: l.qty + delta),
      ];

  double get subtotal => fold<double>(0, (s, l) => s + l.subtotal);
  int get itemCount => fold<int>(0, (s, l) => s + l.qty);
}

enum CheckoutStatus { idle, submitting, success, failure }

typedef CartSummary = ({int itemCount, double subtotal, double discount, double total});

const Object _unset = Object();

/// T2: the full, immutable cart state shared by all four styles.
class CartState {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.canUndo = false, // only used by Cubit/Bloc (observable by BlocBuilder)
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;
  final bool canUndo;

  // T3: derived values are GETTERS, never stored fields.
  int get itemCount => lines.itemCount;
  double get subtotal => lines.subtotal;
  double get discount => coupon == kCouponCode ? subtotal * kCouponRate : 0.0;
  double get total => subtotal - discount;
  CartSummary get summary =>
      (itemCount: itemCount, subtotal: subtotal, discount: discount, total: total);

  /// Nullable fields use a sentinel so `copyWith(coupon: null)` really clears them.
  CartState copyWith({
    List<CartLine>? lines,
    Object? coupon = _unset,
    Object? couponError = _unset,
    CheckoutStatus? status,
    Object? orderId = _unset,
    Object? checkoutError = _unset,
    bool? canUndo,
  }) =>
      CartState(
        lines: lines ?? this.lines,
        coupon: identical(coupon, _unset) ? this.coupon : coupon as String?,
        couponError: identical(couponError, _unset) ? this.couponError : couponError as String?,
        status: status ?? this.status,
        orderId: identical(orderId, _unset) ? this.orderId : orderId as String?,
        checkoutError:
            identical(checkoutError, _unset) ? this.checkoutError : checkoutError as String?,
        canUndo: canUndo ?? this.canUndo,
      );

  /// Pure coupon logic (shared by every style).
  CartState withCoupon(String code) {
    final c = code.trim().toUpperCase();
    if (c == kCouponCode) return copyWith(coupon: c, couponError: null);
    return copyWith(coupon: null, couponError: 'Invalid coupon code');
  }

  // Value equality: required so Riverpod/Cubit/Bloc can skip identical states.
  @override
  bool operator ==(Object other) =>
      other is CartState &&
      listEquals(other.lines, lines) &&
      other.coupon == coupon &&
      other.couponError == couponError &&
      other.status == status &&
      other.orderId == orderId &&
      other.checkoutError == checkoutError &&
      other.canUndo == canUndo;

  @override
  int get hashCode => Object.hash(
      Object.hashAll(lines), coupon, couponError, status, orderId, checkoutError, canUndo);

  @override
  String toString() =>
      'CartState(items: $itemCount, total: ${total.toStringAsFixed(2)}, coupon: $coupon, '
      'couponError: $couponError, status: ${status.name}, canUndo: $canUndo)';
}
