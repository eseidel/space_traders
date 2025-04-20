import 'dart:io';

import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/plan/trading.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:protocol/protocol.dart' as api;
import 'package:server/read_async.dart';

Future<api.DealsNearbyResponse> dealsNearby({
  required FileSystem fs,
  required Database db,
  required ShipType shipType,
  required int limit,
  required WaypointSymbol? maybeStart,
  required int credits,
}) async {
  final systemsCache = SystemsCache.load(fs);
  final marketListings = await MarketListingSnapshot.load(db);
  final jumpGates = await JumpGateSnapshot.load(db);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  // Can't use loadSystemConnectivity because need constructionSnapshot later.
  final systemConnectivity = SystemConnectivity.fromJumpGates(
    jumpGates,
    constructionSnapshot,
  );
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );
  final marketPrices = await MarketPriceSnapshot.loadAll(db);

  final agentCache = await AgentCache.load(db);
  final contractSnapshot = await ContractSnapshot.load(db);
  final centralCommand = CentralCommand();

  final startWaypoint =
      maybeStart == null
          ? agentCache!.headquarters(systemsCache)
          : systemsCache.waypoint(maybeStart);

  final construction = await centralCommand.computeActiveConstruction(
    db,
    agentCache!,
    systemsCache,
  );
  centralCommand.activeConstruction = construction;

  final exportCache = TradeExportCache.load(fs);
  final charting = await ChartingSnapshot.load(db);

  if (construction != null) {
    centralCommand
        .subsidizedSellOpps = await computeConstructionMaterialSubsidies(
      db,
      systemsCache,
      exportCache,
      marketListings,
      charting,
      construction,
    );
  }

  final behaviors = await BehaviorSnapshot.load(db);

  final extraSellOpps = <SellOpp>[];
  if (centralCommand.isContractTradingEnabled) {
    extraSellOpps.addAll(
      centralCommand.contractSellOpps(agentCache, behaviors, contractSnapshot),
    );
  }
  if (centralCommand.isConstructionTradingEnabled) {
    extraSellOpps.addAll(centralCommand.constructionSellOpps(behaviors));
  }

  final shipyardShips = ShipyardShipCache.load(fs);
  final ship = shipyardShips[shipType]!;
  final shipSpec = ship.shipSpec;

  final marketScan = scanReachableMarkets(
    systemsCache,
    systemConnectivity,
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
            systemsCache,
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

  final fs = context.read<FileSystem>();
  final db = await context.readAsync<Database>();
  final logger = context.read<Logger>();

  final response = await runWithLogger(logger, () async {
    final result = await dealsNearby(
      fs: fs,
      db: db,
      shipType: request.shipType ?? api.GetDealsNearbyRequest.defaultShipType,
      limit: request.limit ?? api.GetDealsNearbyRequest.defaultLimit,
      credits: request.credits ?? api.GetDealsNearbyRequest.defaultCredits,
      maybeStart: request.start,
    );
    return result;
  });
  return Response.json(body: response.toJson());
}
