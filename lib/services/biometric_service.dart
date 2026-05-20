import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import '../core/utils/app_logger.dart';

/// Handles device biometric authentication using [local_auth].
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check whether the device supports biometric authentication.
  Future<bool> get isDeviceSupported => _localAuth.isDeviceSupported();

  /// Check whether biometrics are enrolled and available.
  Future<bool> get canCheckBiometrics => _localAuth.canCheckBiometrics;

  /// List of enrolled biometric types (fingerprint, face, etc.).
  Future<List<BiometricType>> get availableBiometrics => _localAuth.getAvailableBiometrics();

  /// Prompt the user for biometric authentication.
  /// Returns `true` if authenticated successfully.
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to access Hiraal Chronic Care',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Biometric authentication required',
            cancelButton: 'Cancel',
            biometricHint: 'Verify your identity',
            biometricNotRecognized: 'Not recognized, try again',
            biometricRequiredTitle: 'Biometric authentication is required',
            biometricSuccess: 'Authentication successful',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription: 'Please set up device credentials',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Please set up biometric authentication in Settings',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Please set up biometric authentication in Settings',
            lockOut: 'Please reenable biometric authentication',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      log.e('Biometric authentication error', error: e);
      return false;
    }
  }

  /// Cancel any in-flight authentication.
  Future<bool> stopAuthentication() => _localAuth.stopAuthentication();
}
