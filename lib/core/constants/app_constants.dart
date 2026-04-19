class AppConstants {
  AppConstants._();

  static const String appName = 'CuentasClaras';
  static const String appTagline = 'Tu negocio, sin cuentas pendientes.';

  static const String supabaseUrl =
      'https://xirbjlrongsjhlhhdrys.supabase.co';

  static const String supabaseAnonKey =
      'sb_publishable__UH-rqo8ybNi96PsNtdgGg_NnDoft8Z';

  static const int defaultLowStockThreshold = 5;
  static const int pageSize = 25;

  static const String tableProducts = 'products';
  static const String tableCategories = 'categories';
  static const String tableSuppliers = 'suppliers';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';
  static const String tableNotifications = 'notifications';
}