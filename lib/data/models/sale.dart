import 'package:flutter/material.dart';

enum PaymentMethod { cash, card, transfer, other }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Efectivo',
        PaymentMethod.card => 'Tarjeta',
        PaymentMethod.transfer => 'Transferencia',
        PaymentMethod.other => 'Otro',
      };

  String get icon => switch (this) {
        PaymentMethod.cash => '💵',
        PaymentMethod.card => '💳',
        PaymentMethod.transfer => '🏦',
        PaymentMethod.other => '📋',
      };
}

@immutable
class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.sku,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? sku;

  double get subtotal => unitPrice * quantity;

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        productId: j['product_id'] as String,
        productName: j['product_name'] as String,
        quantity: j['quantity'] as int,
        unitPrice: (j['unit_price'] as num).toDouble(),
        sku: j['sku'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'sku': sku,
      };
}

@immutable
class Sale {
  const Sale({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String userId;
  final List<SaleItem> items;
  final double total;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final String? notes;

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  int get uniqueProducts => items.length;

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        items: (j['items'] as List<dynamic>?)
                ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        total: (j['total'] as num).toDouble(),
        paymentMethod: PaymentMethod.values.firstWhere(
          (p) => p.name == (j['payment_method'] as String?),
          orElse: () => PaymentMethod.cash,
        ),
        createdAt: DateTime.parse(j['created_at'] as String),
        notes: j['notes'] as String?,
      );
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.productId,
    required this.productName,
    required this.message,
    required this.currentStock,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String productId;
  final String productName;
  final String message;
  final int currentStock;
  final DateTime createdAt;
  final bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        productId: j['product_id'] as String,
        productName: j['product_name'] as String? ?? 'Producto',
        message: j['message'] as String,
        currentStock: j['current_stock'] as int? ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
        isRead: j['is_read'] as bool? ?? false,
      );
}
