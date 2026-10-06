import 'package:flutter/material.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import 'router.dart';
import 'theme.dart';

class SoleNoteApp extends StatelessWidget {
  const SoleNoteApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Petal & Ledger',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppShell(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppDestination _destination = AppDestination.home;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(_destination),
              child: _destination == AppDestination.home
                  ? const DashboardPage()
                  : _PlaceholderPage(destination: _destination),
            ),
          ),
        ),
        bottomNavigationBar: _BottomBar(
          selected: _destination,
          onSelected: (value) => setState(() => _destination = value),
        ),
      );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selected, required this.onSelected});
  final AppDestination selected;
  final ValueChanged<AppDestination> onSelected;

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
              children: AppRouter.destinations.map((destination) {
                final isSelected = selected == destination;
                final isRecord = destination == AppDestination.record;
                return Expanded(
                  child: InkResponse(
                    onTap: () => onSelected(destination),
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
                                color: isSelected ? Colors.white : AppColors.rose,
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
                              color: isSelected ? AppColors.rose : AppColors.muted,
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
