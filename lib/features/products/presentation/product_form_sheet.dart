import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/money.dart';
import '../data/product_repository.dart';
import '../domain/product_draft.dart';

class ProductFormSheet extends ConsumerStatefulWidget {
  const ProductFormSheet({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _category;
  late final TextEditingController _cost;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _lowStock;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _sku = TextEditingController(text: product?.sku ?? '');
    _category = TextEditingController(text: product?.category ?? '');
    _cost = TextEditingController(
      text: product == null ? '' : formatMoneyInput(product.unitCostMinor),
    );
    _price = TextEditingController(
      text: product == null ? '' : formatMoneyInput(product.sellingPriceMinor),
    );
    _stock = TextEditingController(
      text: product == null ? '0' : product.stockQuantity.toString(),
    );
    _lowStock = TextEditingController(
      text: product?.lowStockThreshold?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _category.dispose();
    _cost.dispose();
    _price.dispose();
    _stock.dispose();
    _lowStock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
    ),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.product == null ? 'Add a product' : 'Edit product',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.muted,
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _name,
                label: 'Product name',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a product name.'
                    : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: _sku,
                      label: 'SKU (optional)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                      controller: _category,
                      label: 'Category (optional)',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _moneyField(controller: _cost, label: 'Unit cost'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _moneyField(
                      controller: _price,
                      label: 'Selling price',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: _stock,
                      label: widget.product == null
                          ? 'Opening stock'
                          : 'Stock on hand',
                      keyboardType: TextInputType.number,
                      enabled: widget.product == null,
                      validator: _integerValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                      controller: _lowStock,
                      label: 'Low-stock alert',
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? null
                          : _integerValidator(value),
                    ),
                  ),
                ],
              ),
              if (widget.product != null) ...[
                const SizedBox(height: 7),
                const Text(
                  'Stock changes are recorded separately to keep a clear history.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.product == null
                                ? 'Save product'
                                : 'Save changes',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enabled = true,
  }) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: enabled ? AppColors.surface : AppColors.cream,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
  );

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (value) => value == null || parseMoneyToMinorUnits(value) == null
        ? 'Enter a valid amount.'
        : null,
    decoration: InputDecoration(
      labelText: label,
      prefixText: 'KES ',
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
  );

  String? _integerValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0 ? 'Enter a whole number.' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = ProductDraft(
      name: _name.text,
      sku: _sku.text,
      category: _category.text,
      unitCostMinor: parseMoneyToMinorUnits(_cost.text)!,
      sellingPriceMinor: parseMoneyToMinorUnits(_price.text)!,
      initialStockQuantity: int.parse(_stock.text.trim()),
      lowStockThreshold: _lowStock.text.trim().isEmpty
          ? null
          : int.parse(_lowStock.text.trim()),
    );

    setState(() => _saving = true);
    try {
      final repository = ref.read(productRepositoryProvider);
      if (widget.product == null) {
        await repository.createProduct(draft);
      } else {
        await repository.updateProduct(widget.product!.id, draft);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        final message = error is ProductValidationException
            ? error.message
            : 'Could not save this product. Check that its SKU is unique.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
