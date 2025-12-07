/// Common exception types for API service layer.
///
/// Keeping these in a standalone library allows all services to share a single
/// source of truth for error semantics (e.g. to be mapped to HTTP status codes
/// by a router layer).

// NOTE: No Flutter imports – usable on server side too.

/// Thrown when the caller provides invalid query parameters.
class InvalidQueryException implements Exception {
  /// Human-readable message explaining which parameter was invalid.
  final String message;

  InvalidQueryException(this.message);

  @override
  String toString() => 'InvalidQueryException: $message';
}
