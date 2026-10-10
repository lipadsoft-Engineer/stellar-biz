import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/products/presentation/products_page.dart';
import 'theme.dart';

enum AppDestination { home, products, record, notes, settings }

extension AppDestinationDetails on AppDestination {
  String get path => switch (this) {
        AppDestination.home => '/',
        AppDestination.products => '/products',
        AppDestination.record => '/record',
        AppDestination.notes => '/notes',
        AppDestination.settings => '/settings',
      };

  String get label => switch (this) {
        AppDestination.home => 'Home',
        AppDestination.products => 'Products',
        AppDestination.record => 'Record',
        AppDestination.notes => 'Notes',
        AppDestination.settings => 'Settings',
      };

  IconData get icon => switch (this) {
        AppDestination.home => Icons.home_outlined,
        AppDestination.products => Icons.inventory_2_outlined,
        AppDestination.record => Icons.add_rounded,
        AppDestination.notes => Icons.sticky_note_2_outlined,
        AppDestination.settings => Icons.settings_outlined,
      };

  IconData get selectedIcon => switch (this) {
        AppDestination.home => Icons.home_rounded,
        AppDestination.products => Icons.inventory_2_rounded,
        AppDestination.record => Icons.add_rounded,
        AppDestination.notes => Icons.sticky_note_2_rounded,
        AppDestination.settings => Icons.settings_rounded,
      };

  String get placeholder => switch (this) {
        AppDestination.home => 'Your daily business overview.',
        AppDestination.products => 'Your products will live here.',
        AppDestination.record => 'Record a sale or business expense.',
        AppDestination.notes => 'Keep the little things in one place.',
        AppDestination.settings => 'Make the app feel like yours.',
      };
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppDestination.home.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: AppDestination.values
            .map(
              (destination) => StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: destination.path,
                    name: destination.name,
                    builder: (context, state) =>
                        _destinationPage(destination),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

Widget _destinationPage(AppDestination destination) =>
    destination == AppDestination.home
        ? const DashboardPage()
        : destination == AppDestination.products
            ? const ProductsPage()
            : _PlaceholderPage(destination: destination);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: navigationShell),
        bottomNavigationBar: _BottomBar(
          selectedIndex: navigationShell.currentIndex,
          onSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .035),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 67,
            child: Row(
              children: AppDestination.values.indexed.map((entry) {
                final index = entry.$1;
                final destination = entry.$2;
                final isSelected = selectedIndex == index;
                final isRecord = destination == AppDestination.record;
                return Expanded(
                  child: InkResponse(
                    onTap: () => onSelected(index),
                    radius: 30,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isRecord)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.rose
                                  : AppColors.roseLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(destination.selectedIcon,
                                color:
                                    isSelected ? Colors.white : AppColors.rose,
                                size: 23),
                          )
                        else
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              isSelected
                                  ? destination.selectedIcon
                                  : destination.icon,
                              key: ValueKey(isSelected),
                              color: isSelected
                                  ? AppColors.rose
                                  : AppColors.muted,
                              size: 21,
                            ),
                          ),
                        SizedBox(height: isRecord ? 2 : 4),
                        Text(destination.label,
                            style: TextStyle(
                              color: isSelected && !isRecord
                                  ? AppColors.rose
                                  : AppColors.muted,
                              fontSize: 9,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.destination});
  final AppDestination destination;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: AppColors.roseLight, shape: BoxShape.circle),
                child: Icon(destination.selectedIcon,
                    color: AppColors.rose, size: 28),
              ),
              const SizedBox(height: 18),
              Text(destination.label,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 7),
              Text(destination.placeholder,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 18),
              const Text('Coming in the next build',
                  style: TextStyle(
                      color: AppColors.rose,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
