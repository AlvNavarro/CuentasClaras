import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/supabase_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';

class InventoryRepository {
  static final InventoryRepository instance = InventoryRepository._internal();
  factory InventoryRepository() => instance;
  InventoryRepository._internal();

  final bool useMock = false;
  final _uuid = const Uuid();

  final _stockChangeController = StreamController<void>.broadcast();
  Stream<void> get onStockChanged => _stockChangeController.stream;

  // ─── CATEGORÍAS ─────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final data = await SupabaseService.instance.client
        .from(AppConstants.tableCategories)
        .select()
        .eq('user_id', SupabaseService.instance.ownerId)
        .order('name');
    return (data as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<Category> upsertCategory(Category c) async {
    final result = await SupabaseService.instance.client
        .from(AppConstants.tableCategories)
        .upsert(c.toJson())
        .select()
        .single();
    return Category.fromJson(result);
  }

  Future<void> deleteCategory(String id) async {
    await SupabaseService.instance.client
        .from(AppConstants.tableCategories)
        .delete()
        .eq('id', id);
  }

  // ─── PROVEEDORES ─────────────────────────────────────────────

  Future<List<Supplier>> getSuppliers() async {
    final data = await SupabaseService.instance.client
        .from(AppConstants.tableSuppliers)
        .select()
        .eq('user_id', SupabaseService.instance.ownerId)
        .order('name');
    return (data as List).map((e) => Supplier.fromJson(e)).toList();
  }

  // ─── PRODUCTOS ───────────────────────────────────────────────

  Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
    bool? lowStockOnly,
  }) async {
    var query = SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .select()
        .eq('user_id', SupabaseService.instance.ownerId);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,sku.ilike.%$search%');
    }
    final data = await query.order('name');
    var products = (data as List).map((e) => Product.fromJson(e)).toList();
    if (lowStockOnly == true) {
      products = products.where((p) => p.hasAlert).toList();
    }
    return products;
  }

  // Query directa a Supabase sin filtros adicionales para garantizar datos frescos
  Future<List<Product>> getLowStockProducts() async {
    final data = await SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .select()
        .eq('user_id', SupabaseService.instance.ownerId)
        .order('name');
    final products = (data as List).map((e) => Product.fromJson(e)).toList();
    return products.where((p) => p.hasAlert).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final data = await SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .select()
        .eq('user_id', SupabaseService.instance.ownerId)
        .eq('barcode', barcode)
        .maybeSingle();
    return data != null ? Product.fromJson(data) : null;
  }

  Future<Product> createProduct(Product p) async {
    final userId = SupabaseService.instance.ownerId;
    final result = await SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .insert({
          ...p.toJson(),
          'user_id': userId,
        })
        .select()
        .single();
    _stockChangeController.add(null);
    return Product.fromJson(result);
  }

  Future<Product> updateProduct(Product p) async {
    final result = await SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .update(p.toJson())
        .eq('id', p.id)
        .select()
        .single();
    _stockChangeController.add(null);
    return Product.fromJson(result);
  }

  Future<void> deleteProduct(String id) async {
  // Leer el producto antes de borrarlo para saber su categoría
  final data = await SupabaseService.instance.client
      .from(AppConstants.tableProducts)
      .select()
      .eq('id', id)
      .single();
  final product = Product.fromJson(data);
  final categoryId = product.categoryId;

  // Borrar el producto
  await SupabaseService.instance.client
      .from(AppConstants.tableProducts)
      .delete()
      .eq('id', id);

  // Si tenía categoría, comprobar si quedan más productos en ella
  if (categoryId != null) {
    final remaining = await SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .select()
        .eq('user_id', SupabaseService.instance.ownerId)
        .eq('category_id', categoryId);
    if ((remaining as List).isEmpty) {
      await SupabaseService.instance.client
          .from(AppConstants.tableCategories)
          .delete()
          .eq('id', categoryId);
    }
  }

  _stockChangeController.add(null);
}

  Future<void> adjustStock(String productId, int delta) async {
    try {
      // 1. Leer stock actual
      final data = await SupabaseService.instance.client
          .from(AppConstants.tableProducts)
          .select()
          .eq('id', productId)
          .single();
      final p = Product.fromJson(data);
      final newStock = (p.stock + delta).clamp(0, 999999);

      // 2. Actualizar stock
      await SupabaseService.instance.client
          .from(AppConstants.tableProducts)
          .update({
            'stock': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      // 3. Verificar que el UPDATE se aplicó leyendo de nuevo
      final verify = await SupabaseService.instance.client
          .from(AppConstants.tableProducts)
          .select()
          .eq('id', productId)
          .single();
      final verifiedProduct = Product.fromJson(verify);

      // 4. Generar notificación si el stock verificado tiene alerta
      if (verifiedProduct.hasAlert) {
        final userId = SupabaseService.instance.ownerId;
        await SupabaseService.instance.client
            .from(AppConstants.tableNotifications)
            .insert({
              'user_id': userId,
              'product_id': productId,
              'product_name': verifiedProduct.name,
              'message': verifiedProduct.isOutOfStock
                  ? '${verifiedProduct.name} está AGOTADO. Realiza un pedido urgente.'
                  : '${verifiedProduct.name} tiene solo ${verifiedProduct.stock} ${verifiedProduct.unit}(s) disponibles. Mínimo: ${verifiedProduct.stockMin}.',
              'current_stock': verifiedProduct.stock,
              'is_read': false,
            });

        await NotificationService.instance.showStockAlert(
          productName: verifiedProduct.name,
          currentStock: verifiedProduct.stock,
          isOutOfStock: verifiedProduct.stock == 0,
        );
      }

      // 5. Esperar antes de notificar para que Supabase propague el cambio
      await Future.delayed(const Duration(milliseconds: 300));
      _stockChangeController.add(null);

    } catch (e) {
      print('❌ ERROR adjustStock ($productId): $e');
      rethrow;
    }
  }

  // ─── VENTAS ──────────────────────────────────────────────────

  Future<Sale> createSale({
    required List<SaleItem> items,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    try {
      final total = items.fold<double>(0, (s, i) => s + i.subtotal);
      final userId = SupabaseService.instance.ownerId;
      final saleId = _uuid.v4();

      for (final item in items) {
        await adjustStock(item.productId, -item.quantity);
      }

      final result = await SupabaseService.instance.client
          .from(AppConstants.tableSales)
          .insert({
            'id': saleId,
            'user_id': userId,
            'total': total,
            'payment_method': paymentMethod.name,
            'notes': notes,
            'items': items.map((e) => e.toJson()).toList(),
          })
          .select()
          .single();

      _stockChangeController.add(null);
      return Sale.fromJson(result);
    } catch (e) {
      print('❌ ERROR createSale: $e');
      rethrow;
    }
  }

  Future<List<Sale>> getSales({DateTime? since, int? limit}) async {
    var query = SupabaseService.instance.client
        .from(AppConstants.tableSales)
        .select()
        .eq('user_id', SupabaseService.instance.ownerId);
    if (since != null) {
      query = query.gte('created_at', since.toIso8601String());
    }
    final data = await query
        .order('created_at', ascending: false)
        .limit(limit ?? 100);
    return (data as List).map((e) => Sale.fromJson(e)).toList();
  }

  // ─── NOTIFICACIONES ──────────────────────────────────────────

  Future<List<AppNotification>> getNotifications() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 15));
    final data = await SupabaseService.instance.client
        .from(AppConstants.tableNotifications)
        .select()
        .eq('user_id', SupabaseService.instance.ownerId)
        .gte('created_at', cutoff.toIso8601String()) // solo últimos 15 días
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await SupabaseService.instance.client
        .from(AppConstants.tableNotifications)
        .update({'is_read': true})
        .eq('id', id);
  }

  // ─── DASHBOARD ───────────────────────────────────────────────

  Future<DashboardMetrics> getDashboardMetrics() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));

    final allSales = await getSales();
    final todaySales =
        allSales.where((s) => s.createdAt.isAfter(startOfDay)).toList();
    final weekSales =
        allSales.where((s) => s.createdAt.isAfter(startOfWeek)).toList();
    final lowStock = await getLowStockProducts();
    final products = await getProducts();

    return DashboardMetrics(
      todayRevenue: todaySales.fold(0, (s, x) => s + x.total),
      todaySalesCount: todaySales.length,
      weekRevenue: weekSales.fold(0, (s, x) => s + x.total),
      weekSalesCount: weekSales.length,
      lowStockCount: lowStock.length,
      totalProducts: products.length,
      inventoryValue: products.fold(0, (s, p) => s + (p.priceCost * p.stock)),
      recentSales: allSales.take(8).toList(),
      topLowStock: lowStock.take(5).toList(),
      weekSalesByDay: _weekByDay(weekSales, startOfWeek),
    );
  }

  List<double> _weekByDay(List<Sale> sales, DateTime startOfWeek) {
    final totals = List<double>.filled(7, 0);
    for (final s in sales) {
      final idx = s.createdAt.difference(startOfWeek).inDays;
      if (idx >= 0 && idx < 7) totals[idx] += s.total;
    }
    return totals;
  }
}

class DashboardMetrics {
  DashboardMetrics({
    required this.todayRevenue,
    required this.todaySalesCount,
    required this.weekRevenue,
    required this.weekSalesCount,
    required this.lowStockCount,
    required this.totalProducts,
    required this.inventoryValue,
    required this.recentSales,
    required this.topLowStock,
    required this.weekSalesByDay,
  });

  final double todayRevenue;
  final int todaySalesCount;
  final double weekRevenue;
  final int weekSalesCount;
  final int lowStockCount;
  final int totalProducts;
  final double inventoryValue;
  final List<Sale> recentSales;
  final List<Product> topLowStock;
  final List<double> weekSalesByDay;
}