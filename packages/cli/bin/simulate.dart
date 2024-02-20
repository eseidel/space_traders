import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/mining.dart';
import 'package:cli/printing.dart';
import 'package:cli/ships.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';

// From SAF, surveyor ii stats:
// https://discord.com/channels/792864705139048469/792864705139048472/1159022831355576350
// ##### Survey statistics for X1-AX88-91095A with MOUNT_SURVEYOR_II #####
// In 131770 surveys I got 5.002 deposit per survey and these deposits:
// - 187818 times ICE_WATER deposit, 28.50% of deposits, 142.53% of surveys
// - 93997 times QUARTZ_SAND deposit, 14.26% of deposits, 71.33% of surveys
// - 93948 times AMMONIA_ICE deposit, 14.25% of deposits, 71.30% of surveys
// - 93568 times SILICON_CRYSTALS deposit, 14.20% of deposits, 71.01% of surveys
// - 47370 times ALUMINUM_ORE deposit, 7.19% of deposits, 35.95% of surveys
// - 47238 times IRON_ORE deposit, 7.17% of deposits, 35.85% of surveys
// - 47119 times PRECIOUS_STONES deposit, 7.15% of deposits, 35.76% of surveys
// - 47084 times COPPER_ORE deposit, 7.14% of deposits, 35.73% of surveys
// - 918 times DIAMONDS deposit, 0.14% of deposits, 0.70% of surveys

// SAF on simulating surveys:
// https://discord.com/channels/792864705139048469/792864705139048472/1159409252172050472

class Request {
  Request(this.name, [this.duration = Duration.zero]);
  final String name;
  final Duration duration;
}

const minerNavRoundTrip = Duration(minutes: 2);

Duration half(Duration duration) {
  return Duration(
    microseconds: duration.inMicroseconds ~/ 2,
  );
}

List<Request> routeToRequests(RoutePlan plan) {
  final requests = <Request>[];
  for (final action in plan.actions) {
    switch (action.type) {
      case RouteActionType.emptyRoute:
        break;
      case RouteActionType.navCruise:
        requests.add(Request('navCruise', action.duration));
      case RouteActionType.navDrift:
        requests.add(Request('navDrift', action.duration));
      case RouteActionType.jump:
        requests.add(Request('jump', action.duration));
      case RouteActionType.refuel:
        requests.add(Request('dock', action.duration));
        requests.add(Request('refuel', action.duration));
        requests.add(Request('orbit', action.duration));
    }
  }
  return requests;
}

// time = 60 + 10 * power, this is for 2xL2 + 1xL1 extractors
final extract = Request('extract', const Duration(seconds: 110));
final dock = Request('dock');
final undock = Request('undock');
final sell = Request('sell');
// Depends on the nav distance.
// flightTimeWithinSystemInSeconds
// flightTimeByDistanceAndSpeed
// OreHounds to the nearest market is typically about 1 minute.
final minerNav = Request('nav', half(minerNavRoundTrip));
final transferCargo = Request('transferCargo');

// time = 60 + 10 * power, this is for 3xL2 surveyors
final survey = Request('survey', const Duration(seconds: 120));

final minerLocalSale = [extract, dock, sell, undock];
final minerSystemSale = [extract, minerNav, dock, sell, undock, minerNav];
final minerTransfer = [extract, transferCargo];

Duration cycleTime(List<Request> requests) {
  return requests.fold<Duration>(
    Duration.zero,
    (previousValue, element) => previousValue + element.duration,
  );
}

String c(double value) {
  return creditsString(value.toInt());
}

String cps(double value) {
  return '${creditsString(value.toInt())}/s';
}

String cpm(double value) {
  return '${creditsString(value.toInt())}/m';
}

// For running simulations when we haven't yet found the mount prices.
// Values from 12/27/2023
// https://discord.com/channels/792864705139048469/792864705139048472/1190334200113541120
final mountPrices = <TradeSymbol, int>{
  TradeSymbol.MOUNT_GAS_SIPHON_II: 53000,
  TradeSymbol.MOUNT_SURVEYOR_II: 53000,
  TradeSymbol.MOUNT_MINING_LASER_II: 58000,
};

int mountPrice(
  MarketPrices marketPrices,
  ShipMountSymbolEnum mountSymbol,
) {
  final tradeSymbol = tradeSymbolForMountSymbol(mountSymbol);
  final defaultPrice = mountPrices[tradeSymbol];
  if (defaultPrice == null) {
    throw ArgumentError.value(
      mountSymbol,
      'mountSymbol',
      'No default price found for $mountSymbol',
    );
  }
  return marketPrices.medianPurchasePrice(tradeSymbol) ?? defaultPrice;
}

int costOutMounts(MarketPrices marketPrices, MountSymbolSet mounts) =>
    mounts.map((mount) => mountPrice(marketPrices, mount)).sum;

// For running simulations when we haven't yet found the ship prices.
// Values from 12/27/2023
// https://discord.com/channels/792864705139048469/792864705139048472/1189808193245818990
final shipPrices = {
  ShipType.MINING_DRONE: 42000,
  ShipType.LIGHT_HAULER: 360000,
  ShipType.ORE_HOUND: 340000,
  ShipType.REFINING_FREIGHTER: 2100000,
  ShipType.SURVEYOR: 34000,
};

int shipPrice(ShipyardPriceSnapshot shipyardPrices, ShipType shipType) {
  final defaultPrice = shipPrices[shipType];
  if (defaultPrice == null) {
    throw ArgumentError.value(
      shipType,
      'shipType',
      'No default price found for $shipType',
    );
  }
  return shipyardPrices.medianPurchasePrice(shipType) ?? defaultPrice;
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final marketPrices = await MarketPrices.load(db);
  final systemsCache = SystemsCache.load(fs)!;
  final systemConnectivity = await loadSystemConnectivity(db);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: (_) => false,
  );
  final shipyardPrices = await ShipyardPriceSnapshot.load(db);
  final shipyardShips = ShipyardShipCache.load(fs);
  final shipMounts = ShipMountCache.load(fs);

  final hqSystem = await myHqSystemSymbol(db);
  final hqMine =
      systemsCache.waypointsInSystem(hqSystem).firstWhere((w) => w.isAsteroid);
  const tradeSymbol = TradeSymbol.DIAMONDS;
  const haulerType = ShipType.LIGHT_HAULER;
  final unitsPerHaulerCycle = shipyardShips.capacityForShipType(haulerType)!;

  const surveyorType = ShipType.SURVEYOR;
  final surveyorDefaultMounts = kOreHoundDefault.mounts;
  final surveyorMounts = kSurveyOnlyTemplate.mounts;
  final surveysPerCycle =
      surveysExpectedPerSurveyWithMounts(shipMounts, surveyorMounts);

  const minerType = ShipType.MINING_DRONE;
  final minerDefaultMounts = kOreHoundDefault.mounts;
  final minerMounts = kMineOnlyTemplate.mounts;
  final unitsPerMineCycle = shipyardShips.capacityForShipType(minerType)!;

  // https://discord.com/channels/792864705139048469/792864705139048472/1159170353738825781
  // const diamondRatioToDeposits =
  //     0.13 / 100; // 0.13% of all deposits are diamonds.
  const diamondRatioToSurveys =
      0.64 / 100; // 0.64% of all surveys have a diamond.
  const surveysUntilDiamond = 1 / diamondRatioToSurveys;
  // Only 1 in 5 of the symbols in the survey will be a diamond,
  // technically (18.6%) according to survey_frequencies.dart.
  const diamondRatePerDiamondSurvey = 1 / 5;
  const diamondChancePerExtract = diamondRatePerDiamondSurvey;

  // 10.4 per survey across 286k extractions, survey_extraction_counts.dart
  const extractionsPerSurvey = 10;
  final diamondMedianSellPrice = marketPrices.medianSellPrice(tradeSymbol)!;

  final maxRequestsPerMinute = config.targetRequestsPerSecond * 60;

  final miner = minerTransfer;
  final surveyor = [survey];

  final ship = shipyardShips.shipForTest(
    haulerType,
    origin: hqMine,
  )!;
  final trips = marketsTradingSortedByDistance(
    marketPrices,
    routePlanner,
    tradeSymbol,
    start: ship.waypointSymbol,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
  );

  final haulerRoute = trips[1].route;
  final haulerNav = routeToRequests(haulerRoute);
  final haulerSell = <Request>[...haulerNav, dock, sell, undock, ...haulerNav];

  // One billion credits in a week.
  const goalCredits = 1000000000;
  const timeToGoal = Duration(days: 6); // Assume ramp takes a day.
  final goalCreditsPerSecond = goalCredits / timeToGoal.inSeconds;
  logger.info('Goal credits per second: ${cps(goalCreditsPerSecond)}');

  final goalCreditsPerTenMinutes = goalCreditsPerSecond * 60 * 10;
  logger.info('Goal credits per 10m: ${c(goalCreditsPerTenMinutes)}');

  final minerCycleTime = cycleTime(minerTransfer);
  final minerRequestsPerCycle = miner.length;
  logger.info('Miner cycle time: $minerCycleTime');

  final minerReqeustsPerMinute = minerRequestsPerCycle *
      (const Duration(minutes: 1).inSeconds / minerCycleTime.inSeconds);
  final minerRequestsPerSecond = minerReqeustsPerMinute / 60;
  logger.info('Miner requests per second: $minerRequestsPerSecond');

  final minerCyclesPerMinute =
      const Duration(minutes: 1).inSeconds / minerCycleTime.inSeconds;
  logger.info('Miner cycles per minute: $minerCyclesPerMinute');

  final surveyorCycleTime = cycleTime(surveyor);
  logger.info('\nSurveyor cycle time: $surveyorCycleTime');

  final surveyorRequestsPerCycle = surveyor.length;
  final surveyorRequestsPerMinute = surveyorRequestsPerCycle *
      (const Duration(minutes: 1).inSeconds / surveyorCycleTime.inSeconds);
  final surveyorRequestsPerSecond = surveyorRequestsPerMinute / 60;
  logger.info('Surveyor requests per second: $surveyorRequestsPerSecond');

  final surveyorCyclesPerMinute =
      const Duration(minutes: 1).inSeconds / surveyorCycleTime.inSeconds;
  logger.info('Surveyor cycles per minute: $surveyorCyclesPerMinute');

  final surveysPerMinute = surveyorCyclesPerMinute * surveysPerCycle;
  logger.info('Surveys per minute: $surveysPerMinute');

  final diamondSurveysPerMinute = surveysPerMinute / surveysUntilDiamond;
  logger.info('Diamond surveys per minute: $diamondSurveysPerMinute');

  final surveysNeededPerMinute = minerCyclesPerMinute / extractionsPerSurvey;
  logger.info('Surveys needed per minute: $surveysNeededPerMinute');

  final surveyorsNeededDouble =
      surveysNeededPerMinute / diamondSurveysPerMinute;
  logger.info('Surveyors per squad: $surveyorsNeededDouble');
  final surveyorsNeeded = surveyorsNeededDouble.ceil();

  // Figure out the haulers needed.
  final timeToSellLocation = haulerRoute.duration;
  logger.info('\nTime to sell location: $timeToSellLocation');

  final haulerCycleTime = cycleTime(haulerSell);
  logger.info('Hauler cycle time: $haulerCycleTime');

  final timeToFillHauler =
      minerCycleTime * (unitsPerHaulerCycle / unitsPerMineCycle);
  logger.info('Time to fill hauler: $timeToFillHauler');

  // +1 because you always need a hauler sitting being filled.
  final haulersNeededDouble =
      haulerCycleTime.inSeconds / timeToFillHauler.inSeconds + 1;
  logger.info('Haulers per squad: $haulersNeededDouble');
  final haulersNeeded = haulersNeededDouble.ceil();

  final unitsPerMinute = minerCyclesPerMinute * unitsPerMineCycle;
  // This assumes that any non-diamond extraction is worth 0.
  final creditsPerMinute =
      unitsPerMinute * diamondMedianSellPrice * diamondChancePerExtract;
  logger.info('\nCredits per minute per squad: ${cpm(creditsPerMinute)}');

  final creditsPerTenMinutes = creditsPerMinute * 10;
  logger.info('Credits per 10m per squad: ${c(creditsPerTenMinutes)}');

  final creditsPerSecond = creditsPerMinute / 60;
  logger.info('Credits per second per squad: ${cps(creditsPerSecond)}');

  // final creditsPerSecondPerShip = creditsPerSecond / shipsPerSquad;
  // logger.info('c/s per ship: ${cps(creditsPerSecondPerShip)}');

  final requestsPerMinute = surveyorRequestsPerMinute + minerReqeustsPerMinute;
  final creditsPerRequest = creditsPerMinute / requestsPerMinute;
  logger.info('Credits per request: $creditsPerRequest');

  const minersNeeded = 1;
  final shipsPerSquad = surveyorsNeeded + haulersNeeded + minersNeeded;
  logger.info('\nShips needed per squad: $shipsPerSquad');

  final squadsForGoalDouble = goalCreditsPerTenMinutes / creditsPerTenMinutes;
  logger.info('Squads needed for goal: $squadsForGoalDouble');
  final squadsForGoal = squadsForGoalDouble.ceil();

  final shipsForGoal = squadsForGoal * shipsPerSquad;
  logger.info('Ships needed for goal: $shipsForGoal');

  final maxSquads = maxRequestsPerMinute / requestsPerMinute;
  logger.info('\nMax squads (in $maxRequestsPerMinute r/m budget): $maxSquads');

  final maxShips = maxSquads * shipsPerSquad;
  logger.info('Max ships: $maxShips');

  final maxCreditsPerSecond = maxSquads * creditsPerSecond;
  logger.info('Max credits per second: ${cps(maxCreditsPerSecond)}');

  final maxCreditsPerMinute = maxCreditsPerSecond * 60;
  logger.info('Max credits per minute: ${cpm(maxCreditsPerMinute)}');

  final maxCreditsPerTenMinutes = maxCreditsPerMinute * 10;
  logger.info('Max credits per 10m: ${c(maxCreditsPerTenMinutes)}');

  // Costs
  // Ship costs
  final minerPrice = shipPrice(shipyardPrices, minerType);
  logger.info('\nMiner price: ${creditsString(minerPrice)}');
  final haulerPrice = shipPrice(shipyardPrices, haulerType);
  logger.info('Hauler price: ${creditsString(haulerPrice)}');
  final surveyorPrice = shipPrice(shipyardPrices, surveyorType);
  logger.info('Surveyor price: ${creditsString(surveyorPrice)}');

  final totalShipCost = minerPrice * minersNeeded +
      haulerPrice * haulersNeeded +
      surveyorPrice * surveyorsNeeded;
  logger.info('Total ship cost: ${creditsString(totalShipCost)}');

  // Mount costs
  final minerMountsNeeded = minerMounts.difference(minerDefaultMounts);
  final minerMountCost = costOutMounts(marketPrices, minerMountsNeeded);
  logger.info('Miner mount cost: ${creditsString(minerMountCost)}');
  final surveyorMountsNeeded = surveyorMounts.difference(surveyorDefaultMounts);
  final surveyorMountCost = costOutMounts(marketPrices, surveyorMountsNeeded);
  logger.info('Surveyor mount cost: ${creditsString(surveyorMountCost)}');
  final totalMountCosts =
      minerMountCost * minersNeeded + surveyorMountCost * surveyorsNeeded;
  logger.info('Total mount cost: ${creditsString(totalMountCosts)}');

  final costPerSquad = totalShipCost + totalMountCosts;
  logger.info('Cost per squad: ${creditsString(costPerSquad)}');

  final totalCosts = costPerSquad * squadsForGoal;
  logger.info('Total costs for goal: ${creditsString(totalCosts)}');
}

void main(List<String> args) {
  runOffline(args, command);
}
