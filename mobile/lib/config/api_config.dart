/// Connection settings for the Ticketly backend.
///
/// The base URL is baked in at compile time and can be overridden with a
/// `--dart-define`:
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
/// ```
///
/// The Android emulator reaches the host machine through the special alias
/// `10.0.2.2`, so a backend running on `localhost:8080` of your computer is
/// available to the emulator at:
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
/// ```
class ApiConfig {
  const ApiConfig._();

  /// Used when no `--dart-define=API_BASE_URL` is provided.
  static const String fallbackBaseUrl = 'http://localhost:8080';

  /// Endpoint of a backend running on the host machine, as seen from the
  /// Android emulator.
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8080';

  /// The effective base URL for this build.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: fallbackBaseUrl,
  );
}
