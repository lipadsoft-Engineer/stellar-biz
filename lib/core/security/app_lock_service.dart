import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  AppLockService()
    : _storage = FlutterSecureStorage(),
      _localAuth = LocalAuthentication();

  static final instance = AppLockService();
  static final enabledListenable = ValueNotifier<bool>(false);

  static const _enabledKey = 'app_lock_enabled';
  static const _biometricKey = 'app_lock_biometrics';
  static const _pinKey = 'app_lock_pin';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  Future<bool> readEnabled() async =>
      await _storage.read(key: _enabledKey) == 'true';

  Future<bool> readBiometricsEnabled() async =>
      await _storage.read(key: _biometricKey) == 'true';

  Future<bool> biometricsAvailable() async {
    try {
      if (!await _localAuth.canCheckBiometrics) return false;
      return (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> enable(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _biometricKey, value: 'false');
    await _storage.write(key: _enabledKey, value: 'true');
    enabledListenable.value = true;
  }

  Future<void> changePin(String pin) =>
      _storage.write(key: _pinKey, value: pin);

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  Future<bool> verifyPin(String pin) async =>
      await _storage.read(key: _pinKey) == pin;

  Future<bool> authenticateBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock Petal & Ledger',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> disable() async {
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _biometricKey);
    await _storage.delete(key: _pinKey);
    enabledListenable.value = false;
  }
}
