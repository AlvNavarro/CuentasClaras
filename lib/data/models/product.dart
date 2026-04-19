import 'package:flutter/material.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    this.description,
    this.colorHex = '#4A7A5C',
    this.icon = 'package',
    this.productCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final String colorHex;
  final String icon;
  final int productCount;

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        colorHex: j['color_hex'] as String? ?? '#4A7A5C',
        icon: j['icon'] as String? ?? 'package',
        productCount: j['product_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'color_hex': colorHex,
        'icon': icon,
      };
}

@immutable
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        address: j['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
      };
}

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.priceSale,
    required this.priceCost,
    required this.stock,
    required this.stockMin,
    this.categoryId,
    this.supplierId,
    this.barcode,
    this.description,
    this.imageUrl,
    this.unit = 'ud',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String sku;
  final double priceSale;
  final double priceCost;
  final int stock;
  final int stockMin;
  final String? categoryId;
  final String? supplierId;
  final String? barcode;
  final String? description;
  final String? imageUrl;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get margin => priceSale - priceCost;
  double get marginPct =>
      priceSale > 0 ? ((priceSale - priceCost) / priceSale) * 100 : 0;
  bool get isLowStock => stock > 0 && stock <= stockMin;
  bool get isOutOfStock => stock <= 0;
  bool get hasAlert => stock <= stockMin;

  String get stockStatusLabel {
    if (isOutOfStock) return 'Agotado';
    if (isLowStock) return 'Stock bajo';
    return 'Disponible';
  }

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        sku: j['sku'] as String,
        priceSale: (j['price_sale'] as num).toDouble(),
        priceCost: (j['price_cost'] as num?)?.toDouble() ?? 0,
        stock: j['stock'] as int? ?? 0,
        stockMin: j['stock_min'] as int? ?? 0,
        categoryId: j['category_id'] as String?,
        supplierId: j['supplier_id'] as String?,
        barcode: j['barcode'] as String?,
        description: j['description'] as String?,
        imageUrl: j['image_url'] as String?,
        unit: j['unit'] as String? ?? 'ud',
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sku': sku,
        'price_sale': priceSale,
        'price_cost': priceCost,
        'stock': stock,
        'stock_min': stockMin,
        'category_id': categoryId,
        'supplier_id': supplierId,
        'barcode': barcode,
        'description': description,
        'image_url': imageUrl,
        'unit': unit,
      };

  Product copyWith({
    String? name,
    String? sku,
    double? priceSale,
    double? priceCost,
    int? stock,
    int? stockMin,
    String? categoryId,
    String? supplierId,
    String? barcode,
    String? description,
    String? imageUrl,
    String? unit,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        sku: sku ?? this.sku,
        priceSale: priceSale ?? this.priceSale,
        priceCost: priceCost ?? this.priceCost,
        stock: stock ?? this.stock,
        stockMin: stockMin ?? this.stockMin,
        categoryId: categoryId ?? this.categoryId,
        supplierId: supplierId ?? this.supplierId,
        barcode: barcode ?? this.barcode,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        unit: unit ?? this.unit,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
