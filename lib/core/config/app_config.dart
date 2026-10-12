/// Environment configuration. Phase 1 runs fully on local mock data.
abstract final class AppConfig {
  /// When true, repositories are backed by in-memory mock data.
  static const bool useMockData = true;

  /// Base URL for the Phase 2 backend (Supabase / REST). Empty while mocking.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Simulated latency for mock repositories so loading states are visible.
  static const Duration mockLatency = Duration(milliseconds: 500);
}
