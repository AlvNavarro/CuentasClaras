import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/supabase_service.dart';
import '../../core/constants/app_constants.dart';

class InventoryRepository {
  // SINGLETON
  static final InventoryRepository instance = InventoryRepository._internal();
  factory InventoryRepository() => instance;
  InventoryRepository._internal(); // ← sin _seedMockData()

  final bool useMock = false; // ← Supabase real
  final _uuid = const Uuid();

  // Stream para notificar cambios en tiempo real a todas las pantallas
  final _stockChangeController = StreamController<void>.broadcast();
  Stream<void> get onStockChanged => _stockChangeController.stream;

  // ─── CATEGORÍAS ─────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final data = await SupabaseService.instance.client
        .from(AppConstants.tableCategories)
        .select()
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
        .select();
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,sku.ilike.%$search%');
    }
    final data = await query.order('name');
    var products = (data as List).map((e) => Product.fromJson(e)).toList();
    // Filtro de stock bajo en cliente para evitar problema con columnas
    if (lowStockOnly == true) {
      products = products.where((p) => p.hasAlert).toList();
    }
    return products;
  }

  Future<List<Product>> getLowStockProducts() async {
    return getProducts(lowStockOnly: true);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final data = await SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .select()
        .eq('barcode', barcode)
        .maybeSingle();
    return data != null ? Product.fromJson(data) : null;
  }

  Future<Product> createProduct(Product p) async {
    final userId = SupabaseService.instance.currentUserId ?? '';
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
    await SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .delete()
        .eq('id', id);
    _stockChangeController.add(null);
  }

  Future<void> adjustStock(String productId, int delta) async {
  try {
    final data = await SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .select()
        .eq('id', productId)
        .single();
    final p = Product.fromJson(data);
    final newStock = (p.stock + delta).clamp(0, 999999);

    await SupabaseService.instance.client
        .from(AppConstants.tableProducts)
        .update({
          'stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productId);

    final updated = p.copyWith(stock: newStock);
    if (updated.hasAlert) {
      final userId = SupabaseService.instance.currentUserId ?? '';
      await SupabaseService.instance.client
          .from(AppConstants.tableNotifications)
          .insert({
            'user_id': userId,
            'product_id': productId,
            'product_name': p.name,
            'message': updated.isOutOfStock
                ? '${p.name} está AGOTADO. Realiza un pedido urgente.'
                : '${p.name} tiene solo $newStock ${p.unit}(s) disponibles. Mínimo: ${p.stockMin}.',
            'current_stock': newStock,
            'is_read': false,
          });
    }

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
    final userId = SupabaseService.instance.currentUserId ?? '';
    final saleId = _uuid.v4();

    print('📦 Creando venta para usuario: $userId');
    print('📦 Items: ${items.length}');

    for (final item in items) {
      print('📦 Ajustando stock de ${item.productId} en ${-item.quantity}');
      await adjustStock(item.productId, -item.quantity);
    }

    print('💾 Insertando venta en Supabase...');
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

    print('✅ Venta creada correctamente: $saleId');
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
        .select();
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
    final data = await SupabaseService.instance.client
        .from(AppConstants.tableNotifications)
        .select()
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