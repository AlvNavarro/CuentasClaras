import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Todo en una sola línea para evitar el error del parser
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showStockAlert({
    required String productName,
    required int currentStock,
    required bool isOutOfStock,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    final title = isOutOfStock ? '⚠️ Producto agotado' : '📉 Stock bajo';
    final body = isOutOfStock
        ? '$productName está AGOTADO. Realiza un pedido urgente.'
        : '$productName tiene solo $currentStock unidad${currentStock == 1 ? '' : 'es'} disponibles.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'stock_alerts',
        'Alertas de stock',
        channelDescription: 'Notificaciones cuando el stock baja del mínimo',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(productName.hashCode, title, body, details);
  }
}