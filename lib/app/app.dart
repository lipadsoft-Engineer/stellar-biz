import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/app_lock_gate.dart';
import 'router.dart';
import 'theme.dart';

class SoleNoteApp extends ConsumerWidget {
  const SoleNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Stellar Biz',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: ref.watch(appRouterProvider),
    builder: (context, child) =>
        AppLockGate(child: child ?? const SizedBox.shrink()),
  );
}
