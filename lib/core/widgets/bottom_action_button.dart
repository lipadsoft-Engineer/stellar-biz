import 'package:flutter/material.dart';

class BottomActionButton extends StatelessWidget {
  const BottomActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
  );
}
