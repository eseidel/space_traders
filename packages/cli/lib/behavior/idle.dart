import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Go wait to be filled by miners.
Future<JobResult> _startIdle(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  shipDetail(ship, 'Idling');

  // This is a bit of a hack to manually change the jobIndex.
  // This is done so that we stay in the "idle" Behavior, but also complete
  // being idle any time it resumes, either because the wait is exhausted or
  // because the client was restarted.
  // Waits are kept in-memory and states are persisted to the database.
  state.jobIndex = 1;

  // Return a time in the future so we don't spin hot.
  return JobResult.wait(DateTime.timestamp().add(const Duration(minutes: 10)));
}

/// Go wait to be filled by miners.
Future<JobResult> _completeIdle(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // If we ever resume in this state, we're done idling.
  shipDetail(ship, 'Completing Idle');
  // Return a time in the future so we don't spin hot.
  return JobResult.complete();
}

/// Advance the idle behavior.
final advanceIdle = const MultiJob('Idle', [_startIdle, _completeIdle]).run;
