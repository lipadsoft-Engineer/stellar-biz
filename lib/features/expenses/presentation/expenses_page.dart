import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/money.dart';
import '../data/expense_repository.dart';
import '../domain/expense_draft.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 16, 18, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: 'Back to sales',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expenses',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.5,
                      ),
                    ),
                    Text(
                      'Track your day-to-day business costs',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _addExpense(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: expenses.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Expenses could not be loaded.')),
            data: (items) => _ExpenseList(
              expenses: items,
              onVoid: (expense) => _voidExpense(context, ref, expense),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addExpense(BuildContext context) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ExpenseFormSheet(),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Expense saved.')));
    }
  }

  Future<void> _voidExpense(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void this expense?'),
        content: const Text(
          'It will be removed from active expense totals, while its record is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Void expense'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(expenseRepositoryProvider).voidExpense(expense.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Expense voided.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not void this expense.')),
        );
      }
    }
  }
}

class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({super.key});

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  static const _categories = [
    'Transport',
    'Packaging',
    'Rent',
    'Utilities',
    'Marketing',
    'Fees',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  String _category = _categories.first;
  String _paymentMethod = 'Cash';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add an expense',
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  final amount = parseMoneyToMinorUnits(value ?? '');
                  return amount == null || amount <= 0
                      ? 'Enter an amount greater than zero.'
                      : null;
                },
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'KES ',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'What was it for? (optional)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Paid with'),
                items: const ['Cash', 'Mobile money', 'Bank transfer', 'Other']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _paymentMethod = value ?? _paymentMethod),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.rose,
                ),
                title: const Text(
                  'Expense date',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  _formatDate(_date),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _saving ? null : _chooseDate,
              ),
              const SizedBox(height: 14),
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
                        : const Text('Save expense'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (chosen != null && mounted) {
      setState(
        () => _date = DateTime(
          chosen.year,
          chosen.month,
          chosen.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(expenseRepositoryProvider)
          .createExpense(
            ExpenseDraft(
              amountMinor: parseMoneyToMinorUnits(_amount.text)!,
              category: _category,
              description: _description.text,
              paymentMethod: _paymentMethod,
              transactionDate: _date,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      final message = error is ExpenseValidationException
          ? error.message
          : 'Could not save this expense.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ExpenseList extends StatefulWidget {
  const _ExpenseList({required this.expenses, required this.onVoid});

  final List<Expense> expenses;
  final ValueChanged<Expense> onVoid;

  @override
  State<_ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<_ExpenseList> {
  bool _showVoided = false;

  @override
  Widget build(BuildContext context) {
    final visible = widget.expenses
        .where((expense) => expense.status == (_showVoided ? 'void' : 'active'))
        .toList();
    final total = visible.fold<int>(0, (sum, item) => sum + item.amountMinor);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Active'),
                selected: !_showVoided,
                showCheckmark: false,
                onSelected: (_) => setState(() => _showVoided = false),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Voided'),
                selected: _showVoided,
                showCheckmark: false,
                onSelected: (_) => setState(() => _showVoided = true),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 2, 20, 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.plum,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _showVoided
                      ? 'Voided · excluded from totals'
                      : 'Active expenses',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Text(
                formatKes(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? _ExpenseEmptyState(voided: _showVoided)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _ExpenseCard(
                    expense: visible[index],
                    onVoid: () => widget.onVoid(visible[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense, required this.onVoid});

  final Expense expense;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(13, 10, 6, 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.roseLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            size: 19,
            color: AppColors.rose,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.category,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (expense.description?.isNotEmpty ?? false)
                Text(
                  expense.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              Text(
                '${_formatDate(expense.transactionDate)} · ${expense.paymentMethod ?? 'Unspecified'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatKes(expense.amountMinor),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Void expense',
              onPressed: onVoid,
              icon: const Icon(
                Icons.more_horiz_rounded,
                size: 19,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ExpenseEmptyState extends StatelessWidget {
  const _ExpenseEmptyState({this.voided = false});

  final bool voided;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: AppColors.rose),
          SizedBox(height: 13),
          Text(
            voided ? 'No voided expenses' : 'No expenses yet',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            voided
                ? 'Mistaken entries that you void will appear here.'
                : 'Add a business cost to keep your profit picture complete.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')} ${_months[value.month - 1]} ${value.year}';

const _months = [
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
];
