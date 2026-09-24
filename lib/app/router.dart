import 'package:flutter/material.dart';

enum AppDestination { home, products, record, notes, settings }

extension AppDestinationDetails on AppDestination {
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

abstract final class AppRouter {
  static const home = '/';
  static const destinations = AppDestination.values;
}
