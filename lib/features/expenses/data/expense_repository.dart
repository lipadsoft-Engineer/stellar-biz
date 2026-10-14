import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/expense_draft.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(appDatabaseProvider)),
);

final expensesProvider = StreamProvider<List<Expense>>(
  (ref) => ref.watch(expenseRepositoryProvider).watchExpenses(),
);

class ExpenseRepository {
  const ExpenseRepository(this._database);

  final AppDatabase _database;

  Stream<List<Expense>> watchExpenses() =>
      (_database.select(_database.expenses)..orderBy([
            (expense) => OrderingTerm.desc(expense.transactionDate),
            (expense) => OrderingTerm.desc(expense.id),
          ]))
          .watch();

  Future<int> createExpense(ExpenseDraft draft) {
    final category = draft.category.trim();
    if (draft.amountMinor <= 0) {
      throw const ExpenseValidationException(
        'Enter an expense amount greater than zero.',
      );
    }
    if (category.isEmpty) {
      throw const ExpenseValidationException('Choose an expense category.');
    }

    final description = draft.description?.trim();
    final method = draft.paymentMethod?.trim();
    return _database
        .into(_database.expenses)
        .insert(
          ExpensesCompanion.insert(
            amountMinor: draft.amountMinor,
            category: category,
            description: Value(
              description == null || description.isEmpty ? null : description,
            ),
            transactionDate: Value(draft.transactionDate),
            paymentMethod: Value(
              method == null || method.isEmpty ? null : method,
            ),
          ),
        );
  }

  Future<void> voidExpense(int id) async {
    final rows =
        await (_database.update(_database.expenses)
              ..where((expense) => expense.id.equals(id)))
            .write(const ExpensesCompanion(status: Value('void')));
    if (rows == 0) {
      throw const ExpenseValidationException('This expense no longer exists.');
    }
  }
}
