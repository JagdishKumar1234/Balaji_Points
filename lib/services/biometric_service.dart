import 'package:local_auth/local_auth.dart';
import 'package:balaji_points/core/logger.dart';

/// Thin wrapper around [LocalAuthentication].
///
/// All public methods are safe to call even on devices without biometric
/// hardware — they return false / null rather than throwing.
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device has biometric hardware AND at least one
  /// enrolled biometric credential (fingerprint, face, etc.).
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (e) {
      AppLogger.error('BiometricService.isAvailable', e);
      return false;
    }
  }

  /// Prompt the user for biometric authentication.
  ///
  /// Returns `true` on success, `false` on failure / cancellation / error.
  /// [localizedReason] is shown in the system biometric dialog.
  Future<bool> authenticate({
    String localizedReason = 'Verify your identity to continue',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow device PIN as fallback
          stickyAuth: true,     // keep prompt alive if user switches apps briefly
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      AppLogger.error('BiometricService.authenticate', e);
      return false;
    }
  }
}
