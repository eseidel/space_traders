import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Disable behavior for this ship or all ships?
enum DisableBehavior {
  /// Disable behavior for this ship only.
  thisShip,

  /// Disable behavior for all ships.
  allShips,
}

/// Exception thrown from a Job.
@immutable
class JobException implements Exception {
  /// Create a new job exception.
  const JobException(
    this.message,
    this.timeout, {
    this.disable = DisableBehavior.thisShip,
    this.explicitBehavior,
  });

  /// Why did the job error?
  final String message;

  /// How long should the calling behavior be disabled
  final Duration timeout;

  /// Should the behavior be disabled for this ship or all ships?
  final DisableBehavior disable;

  /// Was this exception thrown in a behavior other than the current one?
  final Behavior? explicitBehavior;

  @override
  String toString() => 'JobException: $message, timeout: $timeout, '
      'disable: $disable, explicitBehavior: $explicitBehavior';

  @override
  bool operator ==(Object other) =>
      other is JobException &&
      message == other.message &&
      timeout == other.timeout &&
      disable == other.disable &&
      explicitBehavior == other.explicitBehavior;

  @override
  int get hashCode => Object.hash(
        message,
        timeout,
        disable,
        explicitBehavior,
      );
}

/// Exception thrown from a Job if the condition is not met.
void jobAssert(
  // ignore: avoid_positional_boolean_parameters
  bool condition,
  String message,
  Duration timeout, {
  DisableBehavior disable = DisableBehavior.thisShip,
}) {
  if (!condition) {
    throw JobException(
      message,
      timeout,
      disable: disable,
    );
  }
}

/// Exception thrown from a Job if the condition is not met.
T assertNotNull<T>(
  T? value,
  String message,
  Duration timeout, {
  DisableBehavior disable = DisableBehavior.thisShip,
}) {
  if (value == null) {
    throw JobException(
      message,
      timeout,
      disable: disable,
    );
  }
  return value;
}
