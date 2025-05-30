import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('BehaviorState JSON roundtrip', () async {
    const shipSymbol = ShipSymbol('S', 1);
    // A BehaviorState would never have all these values at once, just testing
    // that they all roundtrip.
    final state = BehaviorState(
      shipSymbol,
      Behavior.buyShip,
      buyJob: BuyJob(
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        units: 1,
        buyLocation: WaypointSymbol.fromString('S-A-W'),
      ),
      deliverJob: DeliverJob(
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      ),
      routePlan: RoutePlan(
        actions: [
          RouteAction(
            startSymbol: WaypointSymbol.fromString('S-A-W'),
            endSymbol: WaypointSymbol.fromString('S-A-C'),
            type: RouteActionType.navCruise,
            seconds: 10,
            fuelUsed: 10,
          ),
        ],
        fuelCapacity: 10,
        shipSpeed: 10,
      ),
      pickupJob: PickupJob(
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      ),
      mountJob: MountJob(
        mountSymbol: ShipMountSymbol.GAS_SIPHON_I,
        shipyardSymbol: WaypointSymbol.fromString('S-A-W'),
      ),
      shipBuyJob: ShipBuyJob(
        minCreditsNeeded: 100,
        shipyardSymbol: WaypointSymbol.fromString('W-A-Y'),
        shipType: ShipType.EXPLORER,
      ),
      extractionJob: ExtractionJob(
        source: WaypointSymbol.fromString('S-A-W'),
        marketForGood: {
          TradeSymbol.ADVANCED_CIRCUITRY: WaypointSymbol.fromString('S-A-W'),
        },
        extractionType: ExtractionType.mine,
      ),
      systemWatcherJob: SystemWatcherJob(
        systemSymbol: SystemSymbol.fromString('S-A'),
      ),
    );
    final json = state.toJson();
    final newState = BehaviorState.fromJson(json);
    expect(newState.shipSymbol, shipSymbol);
    expect(newState.behavior, Behavior.buyShip);
    expect(newState.toJson(), json);
  });

  test('ExtractionJob immutable', () {
    final job = ExtractionJob(
      source: WaypointSymbol.fromString('S-A-W'),
      marketForGood: {
        TradeSymbol.ADVANCED_CIRCUITRY: WaypointSymbol.fromString('S-A-W'),
      },
      extractionType: ExtractionType.mine,
    );
    final json = job.toJson();
    final newJob = ExtractionJob.fromJson(json);
    expect(newJob, job);
    expect(newJob.toJson(), json);
    expect(newJob.hashCode, job.hashCode);
  });
}
