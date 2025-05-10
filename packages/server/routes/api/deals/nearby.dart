import 'dart:io';

import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/plan/trading.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:protocol/protocol.dart' as api;
import 'package:server/read_async.dart';

Future<api.DealsNearbyResponse> dealsNearby({
  required Database db,
  required ShipType shipType,
  required int limit,
  required WaypointSymbol? maybeStart,
  required int credits,
}) async {
  final systems = await db.systems.snapshotAllSystems();
  final marketListings = await db.marketListings.snapshotAll();
  final routePlanner = await defaultRoutePlanner(db);
  final marketPrices = await db.marketPrices.snapshotAll();

  final agent = await db.getMyAgent();
  final contractSnapshot = await db.contracts.snapshotAll();
  final centralCommand = CentralCommand();

  final startWaypoint =
      maybeStart == null
          ? systems.waypoint(agent!.headquarters)
          : systems.waypoint(maybeStart);

  final construction = await centralCommand.computeActiveConstruction(
    db,
    agent!,
  );
  centralCommand.activeConstruction = construction;

  final exportSnapshot = await db.tradeExports.snapshot();
  final charting = await db.charting.snapshotAllRecords();

  if (construction != null) {
    centralCommand
        .subsidizedSellOpps = await computeConstructionMaterialSubsidies(
      db,
      systems,
      exportSnapshot,
      marketListings,
      charting,
      construction,
    );
  }

  final behaviors = await BehaviorSnapshot.load(db);

  final extraSellOpps = <SellOpp>[];
  if (centralCommand.isContractTradingEnabled) {
    extraSellOpps.addAll(
      centralCommand.contractSellOpps(agent, behaviors, contractSnapshot),
    );
  }
  if (centralCommand.isConstructionTradingEnabled) {
    extraSellOpps.addAll(centralCommand.constructionSellOpps(behaviors));
  }

  final shipyardShips = db.shipyardShips;
  final ship = await shipyardShips.get(shipType);
  final shipSpec = ship!.shipSpec;

  final marketScan = scanReachableMarkets(
    routePlanner.systemConnectivity,
    marketPrices,
    startSystem: startWaypoint.system,
  );
  final costPerFuelUnit =
      marketPrices.medianPurchasePrice(TradeSymbol.FUEL) ??
      config.defaultFuelCost;
  final costPerAntimatterUnit =
      marketPrices.medianPurchasePrice(TradeSymbol.ANTIMATTER) ??
      config.defaultAntimatterCost;

  final dealNotInProgress = avoidDealsInProgress(behaviors.dealsInProgress());
  final deals =
      findDealsFor(
            routePlanner,
            marketScan,
            maxTotalOutlay: credits,
            shipSpec: shipSpec,
            startSymbol: startWaypoint.symbol,
            extraSellOpps: extraSellOpps,
            costPerAntimatterUnit: costPerAntimatterUnit,
            costPerFuelUnit: costPerFuelUnit,
          )
          .take(limit)
          .map(
            (CostedDeal costed) => api.NearbyDeal(
              costed: costed,
              inProgress: !dealNotInProgress(costed.deal),
            ),
          )
          .toList();
  return api.DealsNearbyResponse(
    deals: deals,
    shipType: shipType,
    startSymbol: startWaypoint.symbol,
    credits: credits,
    shipSpec: shipSpec,
    extraSellOpps: extraSellOpps,
    tradeSymbolCount: marketScan.tradeSymbols.length,
  );
}

Future<Response> onRequest(RequestContext context) async {
  final api.GetDealsNearbyRequest request;
  try {
    request = api.GetDealsNearbyRequest.fromQueryParameters(
      context.request.uri.queryParameters,
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body:
          api.ErrorResponse(
            code: 'invalid_request',
            message: 'Invalid request format.',
            details: e.toString(),
          ).toJson(),
    );
  }

  final db = await context.readAsync<Database>();
  final response = await dealsNearby(
    db: db,
    shipType: request.shipType ?? api.GetDealsNearbyRequest.defaultShipType,
    limit: request.limit ?? api.GetDealsNearbyRequest.defaultLimit,
    credits: request.credits ?? api.GetDealsNearbyRequest.defaultCredits,
    maybeStart: request.start,
  );
  return Response.json(body: response.toJson());
}
