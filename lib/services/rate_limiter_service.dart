
import '../models/api_model.dart';

/// Service to handle rate limiting for API calls to prevent overwhelming the server
class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();
  factory RateLimiterService() => _instance;
  RateLimiterService._internal();

  // Store last call times for different API endpoints
  final Map<String, DateTime> _lastCallTimes = {};

  static const Duration _defaultTimeout = Duration(seconds: ApiModel.timeoutInSec);

  /// Check if enough time has passed since the last API call for a specific endpoint
  bool canMakeCall(String endpoint) {
    final lastCall = _lastCallTimes[endpoint];
    if (lastCall == null) return true;

    final timeSinceLastCall = DateTime.now().difference(lastCall);
    return timeSinceLastCall >= _defaultTimeout;
  }

  /// Record that an API call was made for a specific endpoint
  void recordCall(String endpoint) {
    _lastCallTimes[endpoint] = DateTime.now();
  }

  /// Reset rate limit for a specific endpoint (useful for testing or manual reset)
  void resetRateLimit(String endpoint) {
    _lastCallTimes.remove(endpoint);
  }

  /// Reset all rate limits
  void resetAllRateLimits() {
    _lastCallTimes.clear();
  }
}
