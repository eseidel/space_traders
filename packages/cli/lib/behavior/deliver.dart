import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/explorer.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:more/collection.dart';
// Go buy and deliver.
// Used for modules.

/// A job to buy a given item.
@immutable
class BuyJob {
  /// Create a new buy job.
  const BuyJob({
    required this.tradeSymbol,
    required this.units,
    required this.buyLocation,
  });

  /// Create a new buy job from JSON.
  factory BuyJob.fromJson(Map<String, dynamic> json) {
    final tradeSymbol = TradeSymbol.fromJson(json['tradeSymbol'] as String)!;
    final units = json['units'] as int;
    final buyLocation = WaypointSymbol.fromJson(json['buyLocation'] as String);
    return BuyJob(
      tradeSymbol: tradeSymbol,
      units: units,
      buyLocation: buyLocation,
    );
  }

  /// The item to buy.
  final TradeSymbol tradeSymbol;

  /// The number of units to buy.
  final int units;

  /// Where we plan to buy from.
  final WaypointSymbol buyLocation;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tradeSymbol': tradeSymbol.toJson(),
      'units': units,
      'buyLocation': buyLocation.toJson(),
    };
  }
}

/// Deliver tradeSymbol to waypointSymbol and wait until they're all gone.
class DeliverJob {
  /// Create a new deliver job.
  DeliverJob({
    required this.tradeSymbol,
    required this.waypointSymbol,
  });

  /// Create a new deliver job from JSON.
  factory DeliverJob.fromJson(Map<String, dynamic> json) {
    final tradeSymbol = TradeSymbol.fromJson(json['tradeSymbol'] as String)!;
    final waypointSymbol =
        WaypointSymbol.fromJson(json['waypointSymbol'] as String);
    return DeliverJob(
      tradeSymbol: tradeSymbol,
      waypointSymbol: waypointSymbol,
    );
  }

  /// The item to deliver (and wait until empty).
  final TradeSymbol tradeSymbol;

  /// Where we plan to deliver to.
  final WaypointSymbol waypointSymbol;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tradeSymbol': tradeSymbol.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
    };
  }
}

/// Compute the mounts in the given ship's inventory.
Multiset<ShipMountSymbolEnum> countMountsInInventory(Ship ship) {
  final counts = Multiset<ShipMountSymbolEnum>();
  for (final item in ship.cargo.inventory) {
    final mountSymbol = mountSymbolForTradeSymbol(item.tradeSymbol);
    // Will be null if the item isn't a mount.
    if (mountSymbol == null) {
      continue;
    }
    counts.add(mountSymbol, item.units);
  }
  return counts;
}

/// Compute the mounts mounted on the given ship.
Multiset<ShipMountSymbolEnum> countMountedMounts(Ship ship) {
  return Multiset<ShipMountSymbolEnum>.fromIterable(
    ship.mounts.map((m) => m.symbol),
  );
}

/// Compute the mounts needed to make the given ship match the given template.
Multiset<ShipMountSymbolEnum> mountsNeededForShip(
  Ship ship,
  ShipTemplate template,
) {
  return template.mounts.difference(countMountedMounts(ship));
}

class _BuyRequest {
  _BuyRequest({
    required this.tradeSymbol,
    required this.units,
  });

  final TradeSymbol tradeSymbol;
  final int units;
}

_BuyRequest? _buyRequestFromNeededMounts(Multiset<ShipMountSymbolEnum> needed) {
  if (needed.isEmpty) {
    return null;
  }
  // Check each of the needed mounts for availability and affordability.

  final mountSymbol = needed.first;
  final units = needed[mountSymbol];
  final tradeSymbol = tradeSymbolForMountSymbol(mountSymbol)!;
  return _BuyRequest(tradeSymbol: tradeSymbol, units: units);
}

/// This is an attempt towards a compound job.
class DeliverState {
  /// Create a new deliver state.
  DeliverState(
    this.buyJob, {
    this.jobIndex = 0,
  });

  /// Which job are we on?
  int jobIndex;

  /// The buy job state.
  final BuyJob buyJob;
}

enum _JobResultType {
  waitOrLoop,
  complete,
  error,
}

/// Disable behavior for this ship or all ships?
enum DisableBehavior {
  /// Disable behavior for this ship only.
  thisShip,

  /// Disable behavior for all ships.
  allShips,
}

/// Error result from a Job.
class JobError {
  /// Create a new job error.
  JobError(this.why, this.timeout, this.disable)
      : assert(why.isNotEmpty, 'why must not be empty'),
        assert(timeout.inSeconds > 0, 'timeout must be positive');

  /// Why did the job error?
  final String why;

  /// How long should the calling behavior be disabled
  final Duration timeout;

  /// Should the behavior be disabled for this ship or all ships?
  final DisableBehavior disable;
}

/// The result from doJob
class JobResult {
  /// Wait tells the caller to return out the DateTime? to have the ship
  /// wait.  Does not advance to the next job.
  JobResult.wait(DateTime? wait)
      : _type = _JobResultType.waitOrLoop,
        _waitTime = wait,
        _error = null;

  /// Complete tells the caller this job is complete.  If wait is null
  /// the caller may continue to the next job, otherwise it should wait
  /// until the given time.
  JobResult.complete([DateTime? wait])
      : _type = _JobResultType.complete,
        _waitTime = wait,
        _error = null;

  /// Error tells the caller this job completed with an error.  The caller
  /// should return out the error.
  JobResult.error(
    String why,
    Duration timeout, [
    DisableBehavior disable = DisableBehavior.thisShip,
  ])  : _type = _JobResultType.error,
        _waitTime = null,
        _error = JobError(why, timeout, disable);

  final _JobResultType _type;
  final DateTime? _waitTime;
  final JobError? _error;

  /// Is this result an error?
  bool get isError => _type == _JobResultType.error;

  /// Get the JobError from the result.
  JobError get error => _error!;

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
    if (isError) {
      return 'Error: ${error.why}';
    }
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

/// Determine what BuyJob to issue, if any.
Future<BuyJob?> computeBuyJob(
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // Figure out if there are any things needing to be delivered.
  // Look at our ore-hounds, see if they are matching spec.
  // If mounts are missing, see if we can buy them.
  final neededMounts = centralCommand.mountsNeededForAllShips();
  if (neededMounts.isEmpty) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No mounts needed.',
      const Duration(minutes: 20),
    );
    return null;
  }

  // Figure out what item we're supposed to get.
  // If so, in what priority?
  // If we can't buy them, disable the behavior for a while.
  final buyRequest = _buyRequestFromNeededMounts(neededMounts);
  if (buyRequest == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No mounts available.',
      const Duration(minutes: 20),
    );
    return null;
  }

  final tradeSymbol = buyRequest.tradeSymbol;
  final maxToBuy = buyRequest.units;

  final hqSystem = caches.agent.headquartersSymbol.systemSymbol;
  final hqWaypoints = await caches.waypoints.waypointsInSystem(hqSystem);
  final shipyard = hqWaypoints.firstWhereOrNull((w) => w.hasShipyard);
  if (shipyard == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No shipyard in $hqSystem',
      const Duration(days: 1),
    );
    return null;
  }

  // Find the best place to buy it.
  final trip = findBestMarketToBuy(
    caches.marketPrices,
    caches.routePlanner,
    ship,
    tradeSymbol,
    expectedCreditsPerSecond: centralCommand.expectedCreditsPerSecond(ship),
  );
  if (trip == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No market to buy $tradeSymbol',
      const Duration(days: 1),
    );
    return null;
  }
  final buyJob = BuyJob(
    tradeSymbol: tradeSymbol,
    units: maxToBuy,
    // Use price.waypointSymbol in case route is empty.
    buyLocation: trip.price.waypointSymbol,
  );
  return buyJob;
}

/// Execute the BuyJob.
Future<JobResult> doBuyJob(
  BehaviorState state,
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final buyJob = state.buyJob;
  if (buyJob == null) {
    return JobResult.error('No buy job', const Duration(hours: 1));
  }

  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);

  // If we're currently at a market, record the prices and refuel.
  final currentMarket = await visitLocalMarket(
    api,
    caches,
    currentWaypoint,
    ship,
    // We want to always be using super up-to-date market prices for the trader.
    maxAge: const Duration(seconds: 5),
  );
  await centralCommand.visitLocalShipyard(
    api,
    caches.shipyardPrices,
    caches.agent,
    currentWaypoint,
    ship,
  );

  // Regardless of where we are, if we have cargo that isn't part of our deal,
  // try to sell it.
  final result = await handleUnwantedCargoIfNeeded(
    api,
    centralCommand,
    caches,
    ship,
    currentMarket,
    buyJob.tradeSymbol,
  );
  if (!result.isComplete) {
    return result;
  }

  // If we aren't at our buy location, go there.
  if (ship.waypointSymbol != buyJob.buyLocation) {
    final waitUntil = await beingNewRouteAndLog(
      api,
      ship,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      buyJob.buyLocation,
    );
    return JobResult.wait(waitUntil);
  }
  final units = ship.countUnits(buyJob.tradeSymbol);
  if (units >= buyJob.units) {
    shipWarn(ship, 'Deliver already has ${buyJob.units} ${buyJob.tradeSymbol}');
    return JobResult.complete();
  }

  // Otherwise we're at our buy location and we buy.
  await dockIfNeeded(api, ship);
  await purchaseCargoAndLog(
    api,
    caches.marketPrices,
    caches.transactions,
    caches.agent,
    ship,
    buyJob.tradeSymbol,
    buyJob.units,
    AccountingType.capital,
  );
  return JobResult.complete();
}

/// Execute the DeliverJob
Future<JobResult> doDeliverJob(
  BehaviorState state,
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final deliverJob = state.deliverJob;
  if (deliverJob == null) {
    return JobResult.error('No deliver job', const Duration(hours: 1));
  }

  // If we're not at our deliver location, go there.
  if (ship.waypointSymbol != deliverJob.waypointSymbol) {
    final waitUntil = await beingNewRouteAndLog(
      api,
      ship,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      deliverJob.waypointSymbol,
    );
    return JobResult.wait(waitUntil);
  }

  final haveItem = ship.countUnits(deliverJob.tradeSymbol) > 0;
  // If we've handed out all our items, we're done.
  if (!haveItem) {
    centralCommand
      ..completeBehavior(ship.shipSymbol)
      ..setBehavior(
        ship.shipSymbol,
        BehaviorState(ship.shipSymbol, Behavior.idle),
      );
    JobResult.complete();
  }
  // Otherwise we wait.
  final waitUntil = getNow().add(const Duration(minutes: 5));
  return JobResult.wait(waitUntil);
}

/// Init the BuyJob.
Future<JobResult> doInitJob(
  BehaviorState state,
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final buyJob = await computeBuyJob(
    centralCommand,
    caches,
    ship,
  );
  if (buyJob == null) {
    return JobResult.error('No buy job', const Duration(minutes: 20));
  }
  centralCommand.setBuyJob(ship, buyJob);
  return JobResult.complete();
}

/// Disable the current behavior with the given error.
void disableWithJobError(
  Ship ship,
  CentralCommand centralCommand,
  JobError error, {
  Behavior? explicitBehavior,
}) {
  if (error.disable == DisableBehavior.thisShip) {
    centralCommand.disableBehaviorForShip(
      ship,
      error.why,
      error.timeout,
      explicitBehavior: explicitBehavior,
    );
  } else {
    centralCommand.disableBehaviorForAll(
      ship,
      error.why,
      error.timeout,
      explicitBehavior: explicitBehavior,
    );
  }
}

/// Advance the behavior of the given ship.
Future<DateTime?> advanceDeliver(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  shipInfo(ship, 'DELIVER');
  final state = centralCommand.getBehavior(ship.shipSymbol);
  // How would we be here w/o a state?
  if (state == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No behavior state.',
      const Duration(hours: 1),
    );
    return null;
  }

  final jobFunctions = <Future<JobResult> Function(
    BehaviorState,
    Api,
    CentralCommand,
    Caches,
    Ship, {
    DateTime Function() getNow,
  })>[
    doInitJob,
    doBuyJob,
    doDeliverJob,
  ];

  for (var i = 0; i < 10; i++) {
    final jobIndex = state.jobIndex;
    shipInfo(ship, 'DELIVER $jobIndex');
    if (jobIndex < 0 || jobIndex >= jobFunctions.length) {
      centralCommand.disableBehaviorForShip(
        ship,
        'No behavior state.',
        const Duration(hours: 1),
      );
      return null;
    }

    final jobFunction = jobFunctions[jobIndex];
    final result = await jobFunction(
      state,
      api,
      centralCommand,
      caches,
      ship,
    );
    shipInfo(ship, 'DELIVER $jobIndex $result');
    if (result.isComplete) {
      state.jobIndex++;
      if (jobIndex < jobFunctions.length) {
        centralCommand.setBehavior(ship.shipSymbol, state);
      } else {
        centralCommand.completeBehavior(ship.shipSymbol);
        return null;
      }
    }
    if (result.isError) {
      shipInfo(ship, 'Error, disabling.');
      disableWithJobError(ship, centralCommand, result.error);
      return null;
    }
    if (result.shouldReturn) {
      return result.waitTime;
    }
  }
  centralCommand.disableBehaviorForAll(
    ship,
    'Too many deliver job iterations',
    const Duration(hours: 1),
  );
  return null;
}

// This seems related to using haulers for delivery of trade goods.
// They get loaded by miners.
// Then their job is how to figure out where to sell it.
// If there isn't a hauler to load to, the miner just sells?
// If the hauler isn't full it just sleeps until full?
