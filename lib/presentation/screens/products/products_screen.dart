import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repo = InventoryRepository.instance;
  final _search = TextEditingController();
  List<Product> _products = [];
  List<Category> _categories = [];
  String? _selectedCat;
  bool _loading = true;
  bool _onlyAlerts = false;
  bool get _isAdmin => SupabaseService.instance.isAdmin;
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => _load());
    _sub = InventoryRepository.instance.onStockChanged.listen((_) async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final cats = await _repo.getCategories();
    final prods = await _repo.getProducts(
      search: _search.text,
      categoryId: _selectedCat,
      lowStockOnly: _onlyAlerts ? true : null,
    );
    if (mounted) {
      setState(() {
        _categories = cats;
        _products = prods;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _search.dispose();
    super.dispose();
  }

  void _showAddProduct() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductForm(
        repo: _repo,
        categories: _categories,
        onSaved: _load,
      ),
    );
  }

  void _showProductDetail(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProductDetail(
        product: p,
        repo: _repo,
        categories: _categories,
        onUpdate: _load,
        isAdmin: _isAdmin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Productos', style: AppTextStyles.h2),
            Text(
              '${_products.length} artículo${_products.length == 1 ? '' : 's'}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: _onlyAlerts ? AppColors.danger : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() => _onlyAlerts = !_onlyAlerts);
              _load();
            },
            tooltip: 'Solo alertas',
          ),
          const SizedBox(width: 52),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir'),
            )
          : null,
      body: Column(
        children: [
          _searchBar(),
          _categoryFilter(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _products.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: _search.text.isNotEmpty
                            ? 'Sin resultados'
                            : 'Sin productos',
                        subtitle: _search.text.isNotEmpty
                            ? 'Prueba con otro término de búsqueda.'
                            : _isAdmin
                                ? 'Añade tu primer producto.'
                                : 'No hay productos en el catálogo.',
                        action: _isAdmin && _search.text.isEmpty
                            ? _showAddProduct
                            : null,
                        actionLabel: 'Añadir producto',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                          itemCount: _products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => ProductListTile(
                            product: _products[i],
                            onTap: () => _showProductDetail(_products[i]),
                          )
                              .animate()
                              .fadeIn(
                                  delay: Duration(milliseconds: i * 30),
                                  duration: 300.ms)
                              .slideX(begin: 0.05, end: 0),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        controller: _search,
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre, SKU o código de barras...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }

  Widget _categoryFilter() {
    return SizedBox(
      height: 56,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        children: [
          _catChip(null, 'Todos'),
          ...(_categories.map((c) => _catChip(c.id, c.name))),
        ],
      ),
    );
  }

  Widget _catChip(String? id, String label) {
    final selected = _selectedCat == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _selectedCat = id);
          _load();
        },
        showCheckmark: false,
      ),
    );
  }
}

// ─── PRODUCT DETAIL ───────────────────────────────────────────────────────────
class ProductDetail extends StatelessWidget {
  const ProductDetail({
    super.key,
    required this.product,
    required this.repo,
    required this.categories,
    required this.onUpdate,
    this.isAdmin = true,
  });

  final Product product;
  final InventoryRepository repo;
  final List<Category> categories;
  final VoidCallback onUpdate;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final cat = categories.where((c) => c.id == product.categoryId).firstOrNull;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => Container(
        color: AppColors.surface,
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cat != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            cat.name,
                            style: AppTextStyles.caption.copyWith(
                              color: cat.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(product.name, style: AppTextStyles.h1),
                      const SizedBox(height: 4),
                      Text(product.sku, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                StockBadge(product: product),
              ],
            ),
            const SizedBox(height: 24),
            if (isAdmin)
              Row(
                children: [
                  Expanded(child: _infoBox('PVP', Formatters.money(product.priceSale), AppColors.primary, Icons.sell_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _infoBox('COSTE', Formatters.money(product.priceCost), AppColors.textSecondary, Icons.receipt_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _infoBox('MARGEN', '${product.marginPct.toStringAsFixed(0)}%', AppColors.amber, Icons.trending_up_rounded)),
                ],
              )
            else
              _infoBox('PRECIO DE VENTA', Formatters.money(product.priceSale), AppColors.primary, Icons.sell_outlined),
            const SizedBox(height: 12),
            AppCard(
              backgroundColor: product.hasAlert
                  ? (product.isOutOfStock ? AppColors.danger.withOpacity(0.05) : AppColors.warning.withOpacity(0.05))
                  : null,
              borderColor: product.hasAlert
                  ? (product.isOutOfStock ? AppColors.danger.withOpacity(0.3) : AppColors.warning.withOpacity(0.3))
                  : null,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STOCK ACTUAL', style: AppTextStyles.labelSm),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${product.stock}',
                              style: AppTextStyles.kpiLarge(
                                  color: product.hasAlert ? AppColors.danger : AppColors.primary)),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 4),
                            child: Text(product.unit,
                                style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                      Text('Mínimo: ${product.stockMin} ${product.unit}', style: AppTextStyles.caption),
                    ],
                  ),
                  const Spacer(),
                  if (isAdmin)
                    Column(
                      children: [
                        _stockBtn(context, Icons.add_rounded, AppColors.primary, () async {
                          await repo.adjustStock(product.id, 1);
                          onUpdate();
                          if (context.mounted) Navigator.pop(context);
                        }),
                        const SizedBox(height: 8),
                        _stockBtn(context, Icons.remove_rounded, AppColors.accent,
                            product.stock > 0
                                ? () async {
                                    await repo.adjustStock(product.id, -1);
                                    onUpdate();
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                : null),
                      ],
                    ),
                ],
              ),
            ),
            if (product.barcode != null) ...[
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_outlined, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código de barras', style: AppTextStyles.caption),
                        Text(product.barcode!, style: AppTextStyles.label),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => _ProductForm(
                            repo: repo,
                            categories: categories,
                            product: product,
                            onSaved: onUpdate,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.labelSm),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.price(color: color, size: 14)),
        ],
      ),
    );
  }

  Widget _stockBtn(BuildContext context, IconData icon, Color color, VoidCallback? onTap) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44, height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: onTap != null ? color : AppColors.textGhost),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${product.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await repo.deleteProduct(product.id);
      onUpdate();
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ─── PRODUCT FORM ─────────────────────────────────────────────────────────────
class _ProductForm extends StatefulWidget {
  const _ProductForm({
    required this.repo,
    required this.categories,
    this.product,
    required this.onSaved,
  });
  final InventoryRepository repo;
  final List<Category> categories;
  final Product? product;
  final VoidCallback onSaved;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _priceSale = TextEditingController();
  final _priceCost = TextEditingController();
  final _stock = TextEditingController();
  final _stockMin = TextEditingController();
  final _barcode = TextEditingController();
  final _desc = TextEditingController();
  String? _catId;
  String _unit = 'ud';
  bool _saving = false;
  late List<Category> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _sku.text = p.sku;
      _priceSale.text = p.priceSale.toString();
      _priceCost.text = p.priceCost.toString();
      _stock.text = p.stock.toString();
      _stockMin.text = p.stockMin.toString();
      _barcode.text = p.barcode ?? '';
      _desc.text = p.description ?? '';
      _catId = p.categoryId;
      _unit = p.unit;
    } else {
      _stock.text = '0';
      _stockMin.text = '5';
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _sku, _priceSale, _priceCost, _stock, _stockMin, _barcode, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── CREAR CATEGORÍA ────────────────────────────────────────
  Future<void> _createCategory() async {
    final nameCtrl = TextEditingController();
    final selectedColor = ValueNotifier<String>('#4A7A5C');

    final colors = [
      '#4A7A5C', '#B85C38', '#C8903A', '#2A5F7A',
      '#7A2A5F', '#5C4A7A', '#7A5C2A', '#2A7A6F',
    ];

    final created = await showDialog<Category>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                hintText: 'Ej: Panadería',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Color:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: selectedColor,
              builder: (_, current, __) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors.map((hex) {
                  final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
                  final selected = current == hex;
                  return GestureDetector(
                    onTap: () => selectedColor.value = hex,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              try {
                final cat = await widget.repo.upsertCategory(
                  Category(
                    id: '',
                    name: nameCtrl.text.trim(),
                    colorHex: selectedColor.value,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx, cat);
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (created != null && mounted) {
      setState(() {
        _categories.add(created);
        _catId = created.id;
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _sku.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre y SKU son obligatorios')));
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final p = Product(
        id: widget.product?.id ?? '',
        name: _name.text.trim(),
        sku: _sku.text.trim(),
        priceSale: double.tryParse(_priceSale.text) ?? 0,
        priceCost: double.tryParse(_priceCost.text) ?? 0,
        stock: int.tryParse(_stock.text) ?? 0,
        stockMin: int.tryParse(_stockMin.text) ?? 5,
        categoryId: _catId,
        barcode: _barcode.text.isNotEmpty ? _barcode.text.trim() : null,
        description: _desc.text.isNotEmpty ? _desc.text.trim() : null,
        unit: _unit,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.product != null) {
        await widget.repo.updateProduct(p);
      } else {
        await widget.repo.createProduct(p);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.97,
        minChildSize: 0.6,
        expand: false,
        builder: (ctx, scroll) => Container(
          color: AppColors.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(
                            isEdit ? 'Editar producto' : 'Nuevo producto',
                            style: AppTextStyles.h3)),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    _field('Nombre del producto *', _name,
                        hint: 'Ej: Barra de pan artesana'),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _field('SKU / Referencia *', _sku, hint: 'PAN-001')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _unit,
                          decoration: const InputDecoration(labelText: 'Unidad'),
                          items: ['ud', 'kg', 'g', 'L', 'ml', 'bot', 'pq', 'lata', 'bote', 'sobre']
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v ?? 'ud'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _field('PVP (€) *', _priceSale, hint: '1.20', numeric: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Coste (€)', _priceCost, hint: '0.38', numeric: true)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _field('Stock actual', _stock, hint: '0', numeric: true, isInt: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Stock mínimo', _stockMin, hint: '5', numeric: true, isInt: true)),
                    ]),
                    const SizedBox(height: 16),

                    // ─── Categoría con botón crear ─────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _catId,
                            decoration: const InputDecoration(labelText: 'Categoría'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                              ..._categories.map((c) =>
                                  DropdownMenuItem(value: c.id, child: Text(c.name))),
                            ],
                            onChanged: (v) => setState(() => _catId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón crear categoría
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          child: IconButton(
                            onPressed: _createCategory,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: AppColors.primary,
                            tooltip: 'Crear nueva categoría',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _field('Código de barras', _barcode, hint: '8412345000001'),
                    const SizedBox(height: 16),
                    _field('Descripción', _desc, hint: 'Notas opcionales...', maxLines: 3),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: AppColors.onPrimary))
                            : Text(isEdit ? 'Guardar cambios' : 'Crear producto'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, bool numeric = false, bool isInt = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: numeric
          ? (isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true))
          : TextInputType.text,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}