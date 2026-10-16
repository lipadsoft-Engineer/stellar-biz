import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

class PinSetupSheet extends StatefulWidget {
  const PinSetupSheet({required this.title, super.key});

  final String title;

  @override
  State<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<PinSetupSheet> {
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            const Text(
              'Choose a 4 to 8 digit PIN. It is stored securely on this device.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _pinField(_pin, 'New PIN'),
            const SizedBox(height: 10),
            _pinField(_confirmation, 'Confirm PIN'),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.rose, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Text('Save PIN'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _pinField(TextEditingController controller, String label) => TextField(
    controller: controller,
    obscureText: true,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(8),
    ],
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      filled: true,
      fillColor: AppColors.surface,
    ),
  );

  void _save() {
    final pin = _pin.text;
    if (pin.length < 4) {
      setState(() => _error = 'Use at least 4 digits.');
    } else if (pin != _confirmation.text) {
      setState(() => _error = 'The PINs do not match.');
    } else {
      Navigator.pop(context, pin);
    }
  }
}
