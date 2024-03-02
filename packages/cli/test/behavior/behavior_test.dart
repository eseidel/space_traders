import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockApi extends Mock implements Api {}

class _MockDatabase extends Mock implements Database {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockCaches extends Mock implements Caches {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

void main() {
  test('jobAssert', () {
    expect(
      () => jobAssert(true, 'message', const Duration(seconds: 1)),
      returnsNormally,
    );
    expect(
      () => jobAssert(false, 'message', const Duration(seconds: 1)),
      throwsA(isA<JobException>()),
    );

    expect(
      () => failJob('message', const Duration(seconds: 1)),
      throwsA(isA<JobException>()),
    );
  });

  test('JobResult', () {
    expect(() => JobResult.complete().waitTime, throwsStateError);
  });

  test('MultiJob', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    const shipSymbol = ShipSymbol('S', 1);
    final state = BehaviorState(shipSymbol, Behavior.idle);
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final logger = _MockLogger();

    Future<JobResult> step(
      BehaviorState state,
      Api api,
      Database db,
      CentralCommand centralCommand,
      Caches caches,
      Ship ship, {
      DateTime Function() getNow = defaultGetNow,
    }) async {
      return JobResult.complete();
    }

    final multi = MultiJob('test', [step]);
    expect(multi.name, 'test');
    expect(
      () async => await runWithLogger(
        logger,
        () async =>
            await multi.run(api, db, centralCommand, caches, state, ship),
      ),
      returnsNormally,
    );

    // The point of this is to test the "too many loops" behavior which used
    // to be possible to trigger by looping (or could be possible to trigger
    // by incorrectly manipulating jobIndex), but here we're triggering it by
    // defining a multi-job with more than 10 steps.
    // Why does 12 work here but 11 doesn't?
    final eleven = MultiJob('test', List.filled(12, step));
    expect(
      () async => await runWithLogger(
        logger,
        () async =>
            await eleven.run(api, db, centralCommand, caches, state, ship),
      ),
      throwsA(isA<JobException>()),
    );
  });
}
