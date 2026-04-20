import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

class TpvScreen extends StatelessWidget {
  const TpvScreen({super.key});

  static const String _endpoint =
      'https://xirbjlrongsjhlhhdrys.supabase.co/functions/v1/tpv-sale';
  static const String _apiKey = 'tpv-cuentasclaras-2025';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API TPV', style: AppTextStyles.h2),
            Text('Integración con punto de venta', style: AppTextStyles.caption),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [

          AppCard(
            backgroundColor: AppColors.primaryContainer,
            borderColor: AppColors.primary.withOpacity(0.2),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('API activa', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                      Text('Supabase Edge Functions · Deno runtime', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Endpoint
          Text('ENDPOINT', style: AppTextStyles.labelSm),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('POST', style: AppTextStyles.labelSm.copyWith(color: AppColors.onPrimary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _endpoint,
                        style: AppTextStyles.bodySm.copyWith(fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      color: AppColors.textMuted,
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: _endpoint));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Endpoint copiado')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cabeceras
          Text('CABECERAS REQUERIDAS', style: AppTextStyles.labelSm),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _headerRow('Content-Type', 'application/json'),
                const Divider(height: 16),
                _headerRow('x-tpv-key', _apiKey, copyable: true, context: context),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Body
          Text('CUERPO DE LA PETICIÓN (JSON)', style: AppTextStyles.labelSm),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ejemplo', style: AppTextStyles.label),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      color: AppColors.textMuted,
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: _exampleBody));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('JSON copiado')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _exampleBody,
                    style: AppTextStyles.bodySm.copyWith(
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Campos
          Text('CAMPOS DEL JSON', style: AppTextStyles.labelSm),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _fieldRow('user_id', 'string', 'UUID del usuario de CuentasClaras', required: true),
                const Divider(height: 16),
                _fieldRow('total', 'number', 'Total de la venta en euros', required: true),
                const Divider(height: 16),
                _fieldRow('payment_method', 'string', 'cash · card · transfer · other', required: false),
                const Divider(height: 16),
                _fieldRow('items', 'array', 'Lista de productos vendidos', required: true),
                const Divider(height: 16),
                _fieldRow('items[].product_id', 'string', 'UUID del producto en CuentasClaras', required: true),
                const Divider(height: 16),
                _fieldRow('items[].product_name', 'string', 'Nombre del producto', required: true),
                const Divider(height: 16),
                _fieldRow('items[].quantity', 'integer', 'Unidades vendidas', required: true),
                const Divider(height: 16),
                _fieldRow('items[].unit_price', 'number', 'Precio unitario en euros', required: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Respuesta
          Text('RESPUESTA', style: AppTextStyles.labelSm),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _responseRow('200', 'Venta registrada correctamente', AppColors.success),
                const Divider(height: 16),
                _responseRow('400', 'Faltan campos obligatorios', AppColors.warning),
                const Divider(height: 16),
                _responseRow('401', 'Clave TPV inválida', AppColors.danger),
                const Divider(height: 16),
                _responseRow('500', 'Error interno del servidor', AppColors.danger),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _exampleResponse,
                    style: AppTextStyles.bodySm.copyWith(
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seguridad
          Text('SEGURIDAD', style: AppTextStyles.labelSm),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _securityRow(Icons.lock_outline_rounded, 'Autenticación por clave en cabecera x-tpv-key'),
                const Divider(height: 16),
                _securityRow(Icons.https_rounded, 'Comunicación cifrada mediante HTTPS'),
                const Divider(height: 16),
                _securityRow(Icons.shield_outlined, 'RLS en Supabase — cada venta se asigna al user_id correcto'),
                const Divider(height: 16),
                _securityRow(Icons.inventory_outlined, 'Stock actualizado automáticamente tras cada venta TPV'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow(String key, String value, {bool copyable = false, BuildContext? context}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(key, style: AppTextStyles.label.copyWith(fontFamily: 'monospace')),
        ),
        Expanded(
          flex: 3,
          child: Text(value, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
        ),
        if (copyable && context != null)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            color: AppColors.textMuted,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clave copiada')),
              );
            },
          ),
      ],
    );
  }

  Widget _fieldRow(String name, String type, String desc, {required bool required}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.label.copyWith(fontFamily: 'monospace', fontSize: 12)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amberContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(type, style: AppTextStyles.caption.copyWith(color: AppColors.amber)),
                  ),
                  if (required) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('requerido', style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(desc, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _responseRow(String code, String desc, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(code, style: AppTextStyles.label.copyWith(color: color)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(desc, style: AppTextStyles.body)),
      ],
    );
  }

  Widget _securityRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    );
  }

  static const String _exampleBody = '''{
  "user_id": "b605aa3c-eef7-4905-97ed-b2f714b9b68a",
  "total": 5.10,
  "payment_method": "card",
  "items": [
    {
      "product_id": "uuid-del-producto",
      "product_name": "Barra de pan artesana",
      "quantity": 3,
      "unit_price": 1.20,
      "sku": "PAN-001"
    }
  ]
}''';

  static const String _exampleResponse = '''{
  "ok": true,
  "sale_id": "d61f56a0-af6f-4e41-902b-6e1eda50399e",
  "message": "Venta registrada correctamente desde TPV"
}''';
}