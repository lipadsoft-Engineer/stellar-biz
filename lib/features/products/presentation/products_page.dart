import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/product_image_storage.dart';
import '../../inventory/presentation/stock_adjustment_sheet.dart';
import '../../inventory/presentation/stock_history_sheet.dart';
import '../data/product_repository.dart';
import '../domain/product_draft.dart';
import 'product_form_sheet.dart';

enum _ProductAction {
  edit,
  adjustStock,
  stockHistory,
  archive,
  restore,
  delete,
}

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String _search = '';
  bool _lowStockOnly = false;
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 10),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'A clear view of your stock and prices',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
          child: TextField(
            onChanged: (value) => setState(() => _search = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search name or SKU',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        productsAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, _) => const SizedBox(height: 2),
          data: (products) {
            final activeProducts = products.where(
              (product) => !product.isArchived,
            );
            final lowStockCount = activeProducts.where(_isLowStock).length;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 7),
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text('Low stock  $lowStockCount'),
                    selected: _lowStockOnly,
                    onSelected: (selected) =>
                        setState(() => _lowStockOnly = selected),
                    showCheckmark: false,
                  ),
                  FilterChip(
                    label: const Text('Archived'),
                    selected: _showArchived,
                    onSelected: (selected) => setState(() {
                      _showArchived = selected;
                      _lowStockOnly = false;
                    }),
                    showCheckmark: false,
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: 'Products could not be loaded.',
              onRetry: () => ref.invalidate(productsProvider),
            ),
            data: (products) {
              final query = _search.toLowerCase();
              final visible = products.where((product) {
                if (product.isArchived != _showArchived) return false;
                if (_lowStockOnly && !_isLowStock(product)) return false;
                if (query.isEmpty) return true;
                return product.name.toLowerCase().contains(query) ||
                    (product.sku?.toLowerCase().contains(query) ?? false);
              }).toList();

              if (visible.isEmpty) {
                final isEmpty = products
                    .where((product) => product.isArchived == _showArchived)
                    .isEmpty;
                return _EmptyState(
                  title: isEmpty
                      ? _showArchived
                            ? 'No archived products'
                            : 'Your product list is ready'
                      : 'No matching products',
                  subtitle: isEmpty
                      ? _showArchived
                            ? 'Archived products will appear here.'
                            : 'Add a product to start keeping track of stock.'
                      : 'Try another name or clear your filters.',
                  actionLabel: isEmpty && !_showArchived
                      ? 'Add first product'
                      : null,
                  onAction: _addProduct,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
                itemCount: visible.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) => _ProductCard(
                  product: visible[index],
                  isLowStock: _isLowStock(visible[index]),
                  onTap: () => _editProduct(visible[index]),
                  onAction: (action) => _handleAction(visible[index], action),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isLowStock(Product product) =>
      !product.isArchived &&
      product.lowStockThreshold != null &&
      product.stockQuantity <= product.lowStockThreshold!;

  Future<void> _addProduct() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ProductFormSheet(),
    );
    if (saved == true && mounted) _showMessage('Product added.');
  }

  Future<void> _editProduct(Product product) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ProductFormSheet(product: product),
    );
    if (saved == true && mounted) _showMessage('Product updated.');
  }

  Future<void> _adjustStock(Product product) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StockAdjustmentSheet(product: product),
    );
    if (saved == true && mounted) _showMessage('Stock updated.');
  }

  Future<void> _showStockHistory(Product product) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) =>
        StockHistorySheet(productId: product.id, productName: product.name),
  );

  Future<void> _handleAction(Product product, _ProductAction action) async {
    switch (action) {
      case _ProductAction.edit:
        await _editProduct(product);
      case _ProductAction.adjustStock:
        await _adjustStock(product);
      case _ProductAction.stockHistory:
        await _showStockHistory(product);
      case _ProductAction.archive:
        await _runAction(
          () => ref
              .read(productRepositoryProvider)
              .setArchived(product.id, archived: true),
          'Product archived.',
        );
      case _ProductAction.restore:
        await _runAction(
          () => ref
              .read(productRepositoryProvider)
              .setArchived(product.id, archived: false),
          'Product restored.',
        );
      case _ProductAction.delete:
        await _deleteProduct(product);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this product?'),
        content: Text(
          '“${product.name}” will be removed if it has no stock or sales history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(() async {
      await ref.read(productRepositoryProvider).deleteUnusedProduct(product.id);
      try {
        await const ProductImageStorage().delete(product.imagePath);
      } on FileSystemException {
        // The database record is already gone; a stale photo is harmless.
      }
    }, 'Product deleted.');
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (mounted) _showMessage(successMessage);
    } catch (error) {
      if (mounted) {
        final message = error is ProductValidationException
            ? error.message
            : 'That change could not be saved.';
        _showMessage(message);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isLowStock,
    required this.onTap,
    required this.onAction,
  });

  final Product product;
  final bool isLowStock;
  final VoidCallback onTap;
  final ValueChanged<_ProductAction> onAction;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 13, 8, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: product.imagePath == null
                        ? Container(
                            color: AppColors.roseLight,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.rose,
                              size: 21,
                            ),
                          )
                        : Image.file(
                            File(product.imagePath!),
                            fit: BoxFit.cover,
                            cacheWidth: 96,
                            cacheHeight: 96,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.roseLight,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.rose,
                                size: 21,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [product.category, product.sku]
                            .where((value) => value != null && value.isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_ProductAction>(
                  tooltip: 'Product actions',
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _ProductAction.edit,
                      child: Text('Edit'),
                    ),
                    if (!product.isArchived)
                      const PopupMenuItem(
                        value: _ProductAction.adjustStock,
                        child: Text('Adjust stock'),
                      ),
                    const PopupMenuItem(
                      value: _ProductAction.stockHistory,
                      child: Text('Stock history'),
                    ),
                    PopupMenuItem(
                      value: product.isArchived
                          ? _ProductAction.restore
                          : _ProductAction.archive,
                      child: Text(product.isArchived ? 'Restore' : 'Archive'),
                    ),
                    const PopupMenuItem(
                      value: _ProductAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.more_horiz,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                _StockBadge(
                  label: product.isArchived
                      ? 'Archived'
                      : isLowStock
                      ? 'Low stock · ${product.stockQuantity}'
                      : '${product.stockQuantity} in stock',
                  isLow: isLowStock,
                  isArchived: product.isArchived,
                ),
                const Spacer(),
                Text(
                  'Cost  ${formatKes(product.unitCostMinor)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(width: 12),
                Text(
                  'Price  ${formatKes(product.sellingPriceMinor)}',
                  style: const TextStyle(
                    color: AppColors.plum,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.label,
    required this.isLow,
    required this.isArchived,
  });

  final String label;
  final bool isLow;
  final bool isArchived;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: isArchived
          ? AppColors.cream
          : isLow
          ? AppColors.roseLight
          : AppColors.sageLight,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: isArchived
            ? AppColors.muted
            : isLow
            ? AppColors.rose
            : AppColors.sage,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.roseLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.rose,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: const TextStyle(color: AppColors.muted)),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
