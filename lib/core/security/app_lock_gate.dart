import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_lock_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _service = AppLockService.instance;
  bool _loading = true;
  bool _enabled = false;
  bool _locked = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLockService.enabledListenable.addListener(_settingsChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLockService.enabledListenable.removeListener(_settingsChanged);
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final enabled = await _service.readEnabled();
      if (mounted) {
        setState(() {
          _enabled = enabled;
          _locked = enabled;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _settingsChanged() {
    if (!mounted) return;
    setState(() {
      _enabled = AppLockService.enabledListenable.value;
      if (!_enabled) _locked = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_enabled &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused)) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (_loading || (_enabled && _locked))
        Positioned.fill(
          child: Material(
            color: AppColors.cream,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _UnlockScreen(
                    onUnlocked: () => setState(() => _locked = false),
                  ),
          ),
        ),
    ],
  );
}

class _UnlockScreen extends StatefulWidget {
  const _UnlockScreen({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<_UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<_UnlockScreen> {
  final _service = AppLockService.instance;
  final _pin = TextEditingController();
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  bool _working = false;
  String? _message;
  int _failedAttempts = 0;
  DateTime? _blockedUntil;

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _loadBiometrics() async {
    final enabled = await _service.readBiometricsEnabled();
    final available = enabled && await _service.biometricsAvailable();
    if (mounted) {
      setState(() {
        _biometricsEnabled = enabled;
        _biometricsAvailable = available;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: AppColors.roseLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.rose,
                  size: 29,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Stellar Biz',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your PIN to continue',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _pin,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _unlockWithPin(),
                decoration: InputDecoration(
                  labelText: 'App PIN',
                  prefixIcon: const Icon(Icons.password_rounded),
                  errorText: _message,
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _working ? null : _unlockWithPin,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: _working
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock'),
                  ),
                ),
              ),
              if (_biometricsEnabled && _biometricsAvailable) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _working ? null : _unlockWithBiometrics,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Use biometrics'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _unlockWithPin() async {
    final blocked = _blockedUntil;
    if (blocked != null && DateTime.now().isBefore(blocked)) {
      setState(() => _message = 'Please wait before trying again.');
      return;
    }
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      if (await _service.verifyPin(_pin.text)) {
        widget.onUnlocked();
        return;
      }
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _failedAttempts = 0;
        _blockedUntil = DateTime.now().add(const Duration(seconds: 30));
        setState(() => _message = 'Too many attempts. Wait 30 seconds.');
      } else {
        setState(() => _message = 'That PIN is not correct.');
      }
      _pin.clear();
    } catch (_) {
      setState(() => _message = 'Could not check the PIN. Try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _working = true;
      _message = null;
    });
    final authenticated = await _service.authenticateBiometric();
    if (mounted) {
      if (authenticated) {
        widget.onUnlocked();
      } else {
        setState(() => _message = 'Biometric check was not completed.');
      }
      setState(() => _working = false);
    }
  }
}
