import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Exception thrown from a Job.
@immutable
class JobException implements Exception {
  /// Create a new job exception.
  const JobException(
    this.message,
    this.timeout, {
    this.explicitBehavior,
  });

  /// Why did the job error?
  final String message;

  /// How long should the calling behavior be disabled
  final Duration timeout;

  /// Was this exception thrown in a behavior other than the current one?
  final Behavior? explicitBehavior;

  @override
  String toString() => 'JobException: $message, timeout: $timeout, '
      'explicitBehavior: $explicitBehavior';

  @override
  bool operator ==(Object other) =>
      other is JobException &&
      message == other.message &&
      timeout == other.timeout &&
      explicitBehavior == other.explicitBehavior;

  @override
  int get hashCode => Object.hash(
        message,
        timeout,
        explicitBehavior,
      );
}

/// Exception thrown from a Job if the condition is not met.
void jobAssert(
  // ignore: avoid_positional_boolean_parameters
  bool condition,
  String message,
  Duration timeout,
) {
  if (!condition) {
    throw JobException(
      message,
      timeout,
    );
  }
}

/// Exception thrown from a Job if the condition is not met.
T assertNotNull<T>(
  T? value,
  String message,
  Duration timeout,
) {
  if (value == null) {
    throw JobException(
      message,
      timeout,
    );
  }
  return value;
}

enum _JobResultType {
  waitOrLoop,
  complete,
}

/// The result from doJob
class JobResult {
  /// Wait tells the caller to return out the DateTime? to have the ship
  /// wait.  Does not advance to the next job.
  JobResult.wait(DateTime? wait)
      : _type = _JobResultType.waitOrLoop,
        _waitTime = wait;

  /// Complete tells the caller this job is complete.  If wait is null
  /// the caller may continue to the next job, otherwise it should wait
  /// until the given time.
  JobResult.complete([DateTime? wait])
      : _type = _JobResultType.complete,
        _waitTime = wait;

  final _JobResultType _type;
  final DateTime? _waitTime;

  /// Is this job complete?  (Not necessarily the whole behavior)
  bool get isComplete => _type == _JobResultType.complete;

  /// Whether the caller should return after the navigation action
  bool get shouldReturn => _type != _JobResultType.complete;

  /// The wait time if [shouldReturn] is true
  DateTime? get waitTime {
    if (!shouldReturn) {
      throw StateError('Cannot get wait time for non-wait result');
    }
    return _waitTime;
  }

  @override
  String toString() {
    if (isComplete) {
      return 'Complete';
    }
    final wait = _waitTime;
    if (wait == null) {
      return 'Return and loop';
    }
    return 'Wait until ${wait.toIso8601String()}';
  }
}

/// Creates a behavior from jobs.
@immutable
class MultiJob {
  /// Create a new multi-job.
  const MultiJob(this.name, this.jobFunctions);

  /// The name of this multi-job.
  final String name;

  /// The job functions to run.
  final List<
      Future<JobResult> Function(
        BehaviorState,
        Api,
        Database,
        CentralCommand,
        Caches,
        Ship, {
        DateTime Function() getNow,
      })> jobFunctions;

  /// Run the multi-job.
  Future<DateTime?> run(
    Api api,
    Database db,
    CentralCommand centralCommand,
    Caches caches,
    BehaviorState state,
    Ship ship, {
    DateTime Function() getNow = defaultGetNow,
  }) async {
    for (var i = 0; i < 10; i++) {
      shipInfo(ship, '$name ${state.jobIndex}');
      jobAssert(
        state.jobIndex >= 0 && state.jobIndex < jobFunctions.length,
        'Invalid job index ${state.jobIndex}',
        const Duration(hours: 1),
      );

      final jobFunction = jobFunctions[state.jobIndex];
      final result = await jobFunction(
        state,
        api,
        db,
        centralCommand,
        caches,
        ship,
      );
      shipInfo(ship, '$name ${state.jobIndex} $result');
      if (result.isComplete) {
        state.jobIndex++;
        if (state.jobIndex >= jobFunctions.length) {
          state.isComplete = true;
          shipInfo(ship, '$name complete!');
          return null;
        }
      }
      if (result.shouldReturn) {
        return result.waitTime;
      }
    }
    jobAssert(
      false,
      'Too many $name job iterations',
      const Duration(hours: 1),
    );
    return null;
  }
}
