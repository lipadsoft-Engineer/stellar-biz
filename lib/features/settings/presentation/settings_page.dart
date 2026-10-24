import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/security/pin_setup_sheet.dart';
import '../../../core/utils/app_message.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _service = AppLockService.instance;
  bool _loading = true;
  bool _enabled = false;
  bool _biometrics = false;
  bool _biometricsAvailable = false;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _service.readEnabled();
      final biometrics = await _service.readBiometricsEnabled();
      final available = await _service.biometricsAvailable();
      if (mounted) {
        setState(() {
          _enabled = enabled;
          _biometrics = biometrics;
          _biometricsAvailable = available;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
    children: [
      const Text(
        'Settings',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 25,
          fontWeight: FontWeight.w700,
          letterSpacing: -.6,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'A few thoughtful ways to make the app yours',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 24),
      const Text('PRIVACY', style: _sectionLabel),
      const SizedBox(height: 9),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              value: _enabled,
              onChanged: _loading || _working ? null : _setEnabled,
              secondary: const _SettingsIcon(icon: Icons.lock_outline_rounded),
              title: const Text('App lock'),
              subtitle: Text(
                _enabled
                    ? 'Ask for your PIN when you return'
                    : 'Lock the app with a private PIN',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
            if (_enabled) ...[
              const Divider(height: 1, indent: 18, endIndent: 18),
              SwitchListTile.adaptive(
                value: _biometrics && _biometricsAvailable,
                onChanged: _working || !_biometricsAvailable
                    ? null
                    : _setBiometrics,
                secondary: const _SettingsIcon(icon: Icons.fingerprint_rounded),
                title: const Text('Use biometrics'),
                subtitle: Text(
                  _biometricsAvailable
                      ? 'Use face or fingerprint to unlock'
                      : 'No enrolled biometrics found on this device',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              ListTile(
                leading: const _SettingsIcon(icon: Icons.password_rounded),
                title: const Text('Change PIN'),
                subtitle: const Text(
                  'Choose a new 4 to 8 digit PIN',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                ),
                onTap: _working ? null : _changePin,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 11),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: Text(
          'Your PIN is stored in the device’s secure storage. Biometrics are optional; the PIN remains available as a fallback.',
          style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.45),
        ),
      ),
      const SizedBox(height: 23),
      const Text('ABOUT YOUR DATA', style: _sectionLabel),
      const SizedBox(height: 9),
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.roseLight,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.phone_android_rounded, color: AppColors.rose, size: 19),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your products, sales, expenses, and notes are kept on this device.',
                style: TextStyle(
                  color: AppColors.plum,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _setEnabled(bool value) async {
    if (value) {
      final pin = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.cream,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const PinSetupSheet(title: 'Set up app lock'),
      );
      if (pin == null) return;
      setState(() => _working = true);
      try {
        await _service.enable(pin);
        if (mounted) setState(() => _enabled = true);
      } catch (_) {
        _showMessage('Could not enable app lock.', type: AppMessageType.error);
      } finally {
        if (mounted) setState(() => _working = false);
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turn off app lock?'),
        content: const Text('You can turn it back on at any time in Settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep lock'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _working = true);
    try {
      await _service.disable();
      if (mounted) {
        setState(() {
          _enabled = false;
          _biometrics = false;
        });
      }
    } catch (_) {
      _showMessage('Could not turn off app lock.', type: AppMessageType.error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _setBiometrics(bool value) async {
    setState(() => _working = true);
    try {
      await _service.setBiometricsEnabled(value);
      if (mounted) setState(() => _biometrics = value);
    } catch (_) {
      _showMessage(
        'Could not update biometric settings.',
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _changePin() async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PinSetupSheet(title: 'Change app PIN'),
    );
    if (pin == null) return;
    setState(() => _working = true);
    try {
      await _service.changePin(pin);
      _showMessage('App PIN changed.', type: AppMessageType.success);
    } catch (_) {
      _showMessage('Could not change the app PIN.', type: AppMessageType.error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showMessage(String text, {required AppMessageType type}) {
    if (!mounted) return;
    showAppMessage(context, text, type: type);
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: const BoxDecoration(
      color: AppColors.roseLight,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: AppColors.rose, size: 18),
  );
}

const _sectionLabel = TextStyle(
  color: AppColors.muted,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1,
);
