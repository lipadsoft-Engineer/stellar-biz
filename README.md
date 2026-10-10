# Petal & Ledger

A simple, local-first inventory and profit tracker for a sole proprietor. The visual direction is warm cream, dusty rose, sage, and plum, with short transitions and a five-item bottom navigation.

## Project structure

```text
lib/
├── app/                 # App setup, routing, and theme
├── core/                # Shared database, security, errors, and utilities
├── features/
│   ├── dashboard/
│   ├── products/
│   ├── sales/
│   ├── expenses/
│   ├── inventory/
│   ├── reports/
│   ├── notes/
│   └── settings/
└── main.dart
```

Feature code is organized into `data/`, `domain/`, and `presentation/` as it is implemented. Shared concerns live under `core/`.

The app uses `go_router` for tab navigation and Riverpod for dependency and UI state management.

## Development roadmap

### Phase 1 — Foundation
- [x] Create the Flutter project and install dependencies.
- [x] Implement the app theme and reusable UI components.
- [x] Build the main navigation and placeholder screens.
- [x] Configure routing and state management.

### Phase 2 — Local Database
- [x] Configure SQLite and Drift.
- [x] Define product, sale, sale-item, expense, payment, and inventory-movement tables.
- [x] Implement database migrations and transaction handling.
- [x] Add tests for core accounting calculations.

### Phase 3 — Core Features
- [x] Implement product management.
- [x] Implement inventory tracking and stock adjustments.
- [ ] Implement sales recording and payment tracking.
- [ ] Implement expense management.
- [ ] Implement notes.

### Phase 4 — Dashboard and Reports
- [ ] Calculate daily sales, costs, gross profit, expenses, and net profit.
- [ ] Add charts and date-range filters.
- [ ] Implement low-stock alerts.
- [ ] Add CSV export.

### Phase 5 — Security and Reliability
- [ ] Add optional app locking.
- [ ] Implement backup and restore.
- [ ] Add input validation and error handling.
- [ ] Test transaction integrity and historical calculations.
- [ ] Add widget and integration tests.

### Phase 6 — Release Preparation
- [ ] Test on supported devices.
- [ ] Improve accessibility and performance.
- [ ] Prepare application icons and release assets.
- [ ] Build and verify release packages.

## Product scope

- No account or internet connection is required for the initial release.
- Use integer minor currency units for financial calculations; default display currency is KES and should become configurable.
- Keep historical sale prices and costs so later product edits do not rewrite past profit.
- Profit is a management estimate from recorded transactions, not statutory accounting or tax advice.
- Cloud sync, multiple users, barcode scanning, suppliers, and tax features are future options, not MVP requirements.

## Run

```sh
flutter pub get
flutter run
```
