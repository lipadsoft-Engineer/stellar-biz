import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../data/inventory_repository.dart';

class StockHistorySheet extends ConsumerWidget {
  const StockHistorySheet({
    super.key,
    required this.productId,
    required this.productName,
  });

  final int productId;
  final String productName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(productMovementsProvider(productId));
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productName,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: movements.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(
                  child: Text('Stock history could not be loaded.'),
                ),
                data: (items) => items.isEmpty
                    ? const Center(
                        child: Text(
                          'No stock movements yet.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _MovementCard(movement: items[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.movement});
  final InventoryMovement movement;

  @override
  Widget build(BuildContext context) {
    final positive = movement.quantityDelta > 0;
    final time = movement.createdAt.toLocal();
    final dateLabel =
        '${time.day}/${time.month}/${time.year} · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: positive ? AppColors.sageLight : AppColors.roseLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              positive ? Icons.add_rounded : Icons.remove_rounded,
              color: positive ? AppColors.sage : AppColors.rose,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _movementLabel(movement),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  movement.reason ?? dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                if (movement.reason != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${positive ? '+' : '−'}${movement.quantityDelta.abs()}',
            style: TextStyle(
              color: positive ? AppColors.sage : AppColors.rose,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _movementLabel(InventoryMovement movement) =>
      switch (movement.movementType) {
        'opening_balance' => 'Opening stock',
        'restock' => 'Stock received',
        'adjustment' => 'Stock correction',
        'sale' => 'Sale',
        'refund' => 'Refund returned',
        _ => 'Stock movement',
      };
}
