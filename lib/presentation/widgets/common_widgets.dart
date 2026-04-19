import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';

// ─── APP CARD ─────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? AppColors.border,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── KPI CARD ─────────────────────────────────────────────────────────────────
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              if (icon != null) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.kpiMedium(color: color)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

// ─── STOCK BADGE ──────────────────────────────────────────────────────────────
class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (product.isOutOfStock) {
      bg = AppColors.danger.withOpacity(0.12);
      fg = AppColors.danger;
      label = 'Agotado';
    } else if (product.isLowStock) {
      bg = AppColors.warning.withOpacity(0.12);
      fg = AppColors.warning;
      label = 'Stock bajo';
    } else {
      bg = AppColors.success.withOpacity(0.12);
      fg = AppColors.success;
      label = 'En stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.actionLabel,
  });

  final String title;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTextStyles.h3),
        ),
        if (action != null)
          TextButton(
            onPressed: action,
            child: Text(actionLabel ?? 'Ver todo'),
          ),
      ],
    );
  }
}

// ─── PRODUCT LIST TILE ────────────────────────────────────────────────────────
class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
    this.showStock = true,
  });

  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showStock;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Imagen / placeholder
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.sku,
                  style: AppTextStyles.caption,
                ),
                if (showStock) ...[
                  const SizedBox(height: 6),
                  StockBadge(product: product),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (trailing != null)
            trailing!
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.money(product.priceSale),
                  style: AppTextStyles.price(),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.stock} ${product.unit}',
                  style: AppTextStyles.caption.copyWith(
                    color: product.hasAlert
                        ? AppColors.danger
                        : AppColors.textMuted,
                    fontWeight:
                        product.hasAlert ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textGhost,
        size: 22,
      );
}

// ─── SALE LIST TILE ───────────────────────────────────────────────────────────
class SaleListTile extends StatelessWidget {
  const SaleListTile({super.key, required this.sale, this.onTap});
  final Sale sale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amberContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                sale.paymentMethod.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sale.itemCount} producto${sale.itemCount == 1 ? '' : 's'} · ${sale.paymentMethod.label}',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.relative(sale.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            Formatters.money(sale.total),
            style: AppTextStyles.price(color: AppColors.amber),
          ),
        ],
      ),
    );
  }
}

// ─── ALERT TILE ───────────────────────────────────────────────────────────────
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.product, this.onTap});
  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        product.isOutOfStock ? AppColors.danger : AppColors.warning;
    return AppCard(
      onTap: onTap,
      borderColor: color.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              product.isOutOfStock
                  ? Icons.remove_shopping_cart_outlined
                  : Icons.warning_amber_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.isOutOfStock
                      ? 'Agotado — realiza un pedido'
                      : '${product.stock} ${product.unit} restantes (mín. ${product.stockMin})',
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              product.isOutOfStock ? '0' : '${product.stock}',
              style: AppTextStyles.label.copyWith(color: color, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: action,
                child: Text(actionLabel ?? 'Acción'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── LOADING CARD ─────────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 8});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
