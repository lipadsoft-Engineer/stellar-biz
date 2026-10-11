import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/money.dart';
import '../../products/data/product_repository.dart';
import '../data/sale_repository.dart';
import '../domain/record_sale_request.dart';
import '../domain/sale_validation_exception.dart';

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final productList = products.asData?.value;
    final sales = ref.watch(salesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 14),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.6,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Keep each sale and payment in one place',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: productList == null
                    ? null
                    : () => _newSale(context, productList),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New sale'),
              ),
            ],
          ),
        ),
        Expanded(
          child: sales.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Sales could not be loaded.')),
            data: (items) => items.isEmpty
                ? _SalesEmptyState(
                    hasProducts:
                        productList?.any((product) => !product.isArchived) ??
                        false,
                    onAdd: () => _newSale(context, productList ?? []),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) => _SaleCard(
                      sale: items[index],
                      onPayment: () =>
                          _recordPayment(context, ref, items[index]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _newSale(BuildContext context, List<Product> products) async {
    final available = products.where((product) => !product.isArchived).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add an active product before recording a sale.'),
        ),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NewSaleSheet(products: available),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sale recorded.')));
    }
  }

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PaymentSheet(sale: sale),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment added.')));
    }
  }
}

class NewSaleSheet extends ConsumerStatefulWidget {
  const NewSaleSheet({required this.products, super.key});

  final List<Product> products;

  @override
  ConsumerState<NewSaleSheet> createState() => _NewSaleSheetState();
}

class _NewSaleSheetState extends ConsumerState<NewSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _discount = TextEditingController(text: '0');
  final _paid = TextEditingController(text: '0');
  final Map<int, int> _quantities = {};
  String _method = 'Cash';
  bool _saving = false;

  @override
  void dispose() {
    _discount.dispose();
    _paid.dispose();
    super.dispose();
  }

  int get _subtotal => widget.products.fold<int>(
    0,
    (sum, product) =>
        sum + product.sellingPriceMinor * (_quantities[product.id] ?? 0),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 16, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'New sale',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                children: [
                  ...widget.products.map(_productRow),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(child: _amountField(_discount, 'Discount')),
                      const SizedBox(width: 10),
                      Expanded(child: _amountField(_paid, 'Paid now')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      labelText: 'Payment method',
                    ),
                    items:
                        const ['Cash', 'Mobile money', 'Bank transfer', 'Other']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _method = value ?? 'Cash'),
                  ),
                  const SizedBox(height: 14),
                  _SaleTotals(
                    subtotal: _subtotal,
                    discount: _read(_discount.text),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Record sale'),
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

  Widget _productRow(Product product) {
    final quantity = _quantities[product.id] ?? 0;
    final unavailable = product.stockQuantity == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(12, 8, 7, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${formatKes(product.sellingPriceMinor)} · ${product.stockQuantity} in stock',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: quantity == 0
                ? null
                : () => _change(product, quantity - 1),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          SizedBox(
            width: 22,
            child: Text('$quantity', textAlign: TextAlign.center),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: unavailable || quantity >= product.stockQuantity
                ? null
                : () => _change(product, quantity + 1),
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppColors.rose,
          ),
        ],
      ),
    );
  }

  Widget _amountField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        onChanged: (_) => setState(() {}),
        validator: (value) => parseMoneyToMinorUnits(value ?? '') == null
            ? 'Enter a valid amount.'
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'KES ',
          filled: true,
          fillColor: AppColors.surface,
        ),
      );

  void _change(Product product, int quantity) => setState(() {
    if (quantity == 0) {
      _quantities.remove(product.id);
    } else {
      _quantities[product.id] = quantity;
    }
  });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quantities.isEmpty) {
      _message('Add at least one product.');
      return;
    }
    final discount = _read(_discount.text);
    final paid = _read(_paid.text);
    if (discount > _subtotal) {
      _message('Discount cannot exceed the subtotal.');
      return;
    }
    if (paid > _subtotal - discount) {
      _message('Payment cannot exceed the sale total.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(saleRepositoryProvider)
          .recordSale(
            RecordSaleRequest(
              items: _quantities.entries
                  .map(
                    (entry) => RecordSaleLine(
                      productId: entry.key,
                      quantity: entry.value,
                    ),
                  )
                  .toList(),
              discountMinor: discount,
              amountPaidMinor: paid,
              paymentMethod: _method,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      _message(
        error is SaleValidationException
            ? error.message
            : 'Could not record this sale.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _read(String value) => parseMoneyToMinorUnits(value) ?? 0;

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}

class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({required this.sale, super.key});

  final Sale sale;

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final _amount = TextEditingController();
  String _method = 'Cash';
  bool _saving = false;

  int get _balance => widget.sale.totalMinor - widget.sale.amountPaidMinor;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 22,
      right: 22,
      top: 22,
      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add payment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Balance  ·  ${formatKes(_balance)}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'KES ',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Payment method'),
            items: const ['Cash', 'Mobile money', 'Bank transfer', 'Other']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _method = value ?? 'Cash'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save payment'),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    final amount = parseMoneyToMinorUnits(_amount.text);
    if (amount == null || amount <= 0) {
      _message('Enter a payment greater than zero.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(saleRepositoryProvider)
          .recordPayment(
            saleId: widget.sale.id,
            amountMinor: amount,
            paymentMethod: _method,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      _message(
        error is SaleValidationException
            ? error.message
            : 'Could not save this payment.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale, required this.onPayment});

  final Sale sale;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    final balance = sale.totalMinor - sale.amountPaidMinor;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _date(sale.transactionDate),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              _PaymentBadge(status: sale.paymentStatus),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatKes(sale.totalMinor),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (sale.amountPaidMinor > 0)
                Text(
                  'Paid ${formatKes(sale.amountPaidMinor)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
            ],
          ),
          if (balance > 0) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Due ${formatKes(balance)}',
                    style: const TextStyle(
                      color: AppColors.rose,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onPayment,
                  child: const Text('Add payment'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')} ${_month(value.month)} ${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.sageLight : AppColors.roseLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        switch (status) {
          'paid' => 'Paid',
          'partial' => 'Part paid',
          _ => 'Unpaid',
        },
        style: TextStyle(
          color: isPaid ? AppColors.sage : AppColors.rose,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SaleTotals extends StatelessWidget {
  const _SaleTotals({required this.subtotal, required this.discount});
  final int subtotal;
  final int discount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.roseLight,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        _totalLine('Subtotal', subtotal),
        const SizedBox(height: 5),
        _totalLine('Discount', discount),
        const Divider(height: 14),
        _totalLine('Sale total', subtotal - discount, bold: true),
      ],
    ),
  );

  Widget _totalLine(String label, int amount, {bool bold = false}) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
      Text(
        formatKes(amount),
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ],
  );
}

class _SalesEmptyState extends StatelessWidget {
  const _SalesEmptyState({required this.hasProducts, required this.onAdd});
  final bool hasProducts;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.point_of_sale_outlined,
            size: 44,
            color: AppColors.rose,
          ),
          const SizedBox(height: 13),
          Text(
            hasProducts ? 'Ready for your first sale?' : 'Add products first',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hasProducts
                ? 'Choose products, record payment, and stock updates automatically.'
                : 'Your active products will be available here when you record a sale.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (hasProducts) ...[
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New sale'),
            ),
          ],
        ],
      ),
    ),
  );
}
