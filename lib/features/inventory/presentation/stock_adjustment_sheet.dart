import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../data/inventory_repository.dart';
import '../domain/stock_adjustment_request.dart';

class StockAdjustmentSheet extends ConsumerStatefulWidget {
  const StockAdjustmentSheet({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<StockAdjustmentSheet> createState() =>
      _StockAdjustmentSheetState();
}

class _StockAdjustmentSheetState extends ConsumerState<StockAdjustmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  bool _increasing = true;
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
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
              Text(
                'Adjust stock',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.name,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 17),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.roseLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Current stock  ·  ${widget.product.stockQuantity} units',
                  style: const TextStyle(
                    color: AppColors.plum,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Add stock'),
                    icon: Icon(Icons.add_rounded),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Reduce stock'),
                    icon: Icon(Icons.remove_rounded),
                  ),
                ],
                selected: {_increasing},
                onSelectionChanged: (selection) =>
                    setState(() => _increasing = selection.first),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
                  return quantity == null || quantity <= 0
                      ? 'Enter a quantity greater than zero.'
                      : null;
                },
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reason,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) =>
                    !_increasing && (value == null || value.trim().isEmpty)
                    ? 'Add a reason for reducing stock.'
                    : null,
                decoration: InputDecoration(
                  labelText: _increasing
                      ? 'Note (optional)'
                      : 'Reason for correction',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                        : const Text('Save stock change'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(inventoryRepositoryProvider)
          .adjustStock(
            StockAdjustmentRequest(
              productId: widget.product.id,
              quantity: int.parse(_quantity.text),
              kind: _increasing
                  ? StockAdjustmentKind.restock
                  : StockAdjustmentKind.correction,
              reason: _reason.text,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        final message = error is InventoryValidationException
            ? error.message
            : 'Stock could not be updated.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
