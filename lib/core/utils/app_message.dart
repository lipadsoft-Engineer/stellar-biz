import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum AppMessageType { success, error, info }

void showAppMessage(
  BuildContext context,
  String message, {
  AppMessageType type = AppMessageType.info,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final palette = switch (type) {
    AppMessageType.success => (
      background: const Color(0xFFE8F1E9),
      foreground: const Color(0xFF376447),
      border: const Color(0xFFC9DEC9),
      icon: Icons.check_circle_rounded,
    ),
    AppMessageType.error => (
      background: const Color(0xFFF7EAEC),
      foreground: const Color(0xFF7C3F50),
      border: const Color(0xFFE8CDD2),
      icon: Icons.error_outline_rounded,
    ),
    AppMessageType.info => (
      background: AppColors.roseLight,
      foreground: AppColors.plum,
      border: AppColors.border,
      icon: Icons.info_outline_rounded,
    ),
  };

  final textStyle = TextStyle(
    color: palette.foreground,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  final screenWidth = MediaQuery.sizeOf(context).width;
  final maxWidth = math.min(420.0, screenWidth - 32).clamp(140.0, 420.0);
  final textMaxWidth = math.max(48.0, maxWidth - 70);
  final textPainter = TextPainter(
    text: TextSpan(text: message, style: textStyle),
    textDirection: Directionality.of(context),
    maxLines: 4,
    ellipsis: '…',
  )..layout(maxWidth: textMaxWidth);
  final width = math.min(maxWidth, math.max(144.0, textPainter.width + 70));

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: width,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(seconds: type == AppMessageType.error ? 4 : 3),
        content: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: .10),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(palette.icon, color: palette.foreground, size: 19),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
}
