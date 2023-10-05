import 'package:cli/cli.dart';
import 'package:cli/printing.dart';

class Request {
  Request(this.name, [this.duration = Duration.zero]);
  final String name;
  final Duration duration;
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
final nav = Request('nav', const Duration(seconds: 60));
// time = 60 + 10 * power, this is for 3xL2 surveyors
final survey = Request('survey', const Duration(seconds: 120));

Duration cycleTime(List<Request> requests) {
  return requests.fold<Duration>(
    Duration.zero,
    (previousValue, element) => previousValue + element.duration,
  );
}

// RoutePlan _sameSystemRoute() {
//   final ignored = WaypointSymbol.fromString('W-A-Y');
//   final routeToMarket = RoutePlan(
//     fuelCapacity: 0,
//     shipSpeed: 0,
//     actions: [
//       RouteAction(
//         startSymbol: ignored,
//         endSymbol: ignored,
//         type: RouteActionType.navCruise,
//         duration: const Duration(seconds: 60),
//       ),
//     ],
//     fuelUsed: 0,
//   );
//   return routeToMarket;
// }

Future<void> command(FileSystem fs, ArgResults argResults) async {
  // Write out the requests needed for various strategies.
  // e.g. single miner loop (starting orbiting mine)
  // survey x N, extract x M, dock, sell, undock, repeat

  // traveling miner loop (starting in orbit)
  // survey x N, extract x M, nav, dock, sell, undock, nav, repeat

  // surveyor loop (starting in orbit)
  // survey, repeat

  // I'm trying to answer the question of, given a diamond mining strategy,
  // how many credits per request does the fleet make.  And how many copies
  // of said fleet could one expect to have.

  String c(double value) {
    return creditsString(value.toInt());
  }

  String cps(double value) {
    return '${creditsString(value.toInt())}/s';
  }

  String cpm(double value) {
    return '${creditsString(value.toInt())}/m';
  }

  // One billion credits in a week.
  const goalCredits = 1000000000;
  const timeToGoal = Duration(days: 6); // Assume ramp takes a day.
  final goalCreditsPerSecond = goalCredits / timeToGoal.inSeconds;
  logger.info('Goal credits per second: ${cps(goalCreditsPerSecond)}');

  final goalCreditsPerTenMinutes = goalCreditsPerSecond * 60 * 10;
  logger.info('Goal credits per 10m: ${c(goalCreditsPerTenMinutes)}');

  // https://discord.com/channels/792864705139048469/792864705139048472/1159170353738825781
  // const diamondRatioToDeposits =
  //     0.13 / 100; // 0.13% of all deposits are diamonds.
  const diamondRatioToSurveys =
      0.64 / 100; // 0.64% of all surveys have a diamond.
  const surveysUntilDiamond = 1 / diamondRatioToSurveys;
  const diamondRatePerDiamondSurvey = 1 / 5;
  const diamondChancePerExtract = diamondRatePerDiamondSurvey;

  const extractionsPerSurvey = 19;
  const surveysPerCycle = 6; // 3xL2 surveyors
  const diamondMedianSellPrice = 468;
  const unitsPerMineCycle = 60;

  const maxRequestsPerMinute = 170; // Assuming no room for other actions.

  final surveyor = [survey];
  final surveyorCycleTime = cycleTime(surveyor);
  logger.info('Surveyor cycle time: $surveyorCycleTime');

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

  // final miner = [extract, dock, sell, undock];
  final miner = [extract, nav, dock, sell, undock, nav];
  final minerCycleTime = cycleTime(miner);
  final minerRequestsPerCycle = miner.length;
  logger.info('Miner cycle time: $minerCycleTime');

  final minerReqeustsPerMinute = minerRequestsPerCycle *
      (const Duration(minutes: 1).inSeconds / minerCycleTime.inSeconds);
  final minerRequestsPerSecond = minerReqeustsPerMinute / 60;
  logger.info('Miner requests per second: $minerRequestsPerSecond');

  final minerCyclesPerMinute =
      const Duration(minutes: 1).inSeconds / minerCycleTime.inSeconds;
  logger.info('Miner cycles per minute: $minerCyclesPerMinute');

  final surveysNeededPerMinute = minerCyclesPerMinute / extractionsPerSurvey;
  logger.info('Surveys needed per minute: $surveysNeededPerMinute');

  final surveyorsNeeded = surveysNeededPerMinute / diamondSurveysPerMinute;
  logger.info('Surveyors per squad: $surveyorsNeeded');

  const minersNeeded = 1;
  final shipsPerSquad = (surveyorsNeeded + minersNeeded).ceil();
  logger.info('Ships needed per squad: $shipsPerSquad');

  final unitsPerMinute = minerCyclesPerMinute * unitsPerMineCycle;
  // This assumes that any non-diamond extraction is worth 0.
  final creditsPerMinute =
      unitsPerMinute * diamondMedianSellPrice * diamondChancePerExtract;
  logger.info('Credits per minute per squad: ${cpm(creditsPerMinute)}');

  final creditsPerTenMinutes = creditsPerMinute * 10;
  logger.info('Credits per 10m per squad: ${c(creditsPerTenMinutes)}');

  final creditsPerSecond = creditsPerMinute / 60;
  logger.info('Credits per second per squad: ${cps(creditsPerSecond)}');

  final creditsPerSecondPerShip = creditsPerSecond / shipsPerSquad;
  logger.info('Credits per second per ship: ${cps(creditsPerSecondPerShip)}');

  final requestsPerMinute = surveyorRequestsPerMinute + minerReqeustsPerMinute;
  final creditsPerRequest = creditsPerMinute / requestsPerMinute;
  logger.info('Credits per request: $creditsPerRequest');

  final squadsForGoal = goalCreditsPerTenMinutes / creditsPerTenMinutes;
  logger.info('Squads needed for goal: $squadsForGoal');

  final shipsForGoal = squadsForGoal * shipsPerSquad;
  logger.info('Ships needed for goal: $shipsForGoal');

  final maxSquads = maxRequestsPerMinute / requestsPerMinute;
  logger.info('Max squads (in $maxRequestsPerMinute r/m budget): $maxSquads');

  final maxShips = maxSquads * shipsPerSquad;
  logger.info('Max ships: $maxShips');

  final maxCreditsPerSecond = maxSquads * creditsPerSecond;
  logger.info('Max credits per second: ${cps(maxCreditsPerSecond)}');

  final maxCreditsPerMinute = maxCreditsPerSecond * 60;
  logger.info('Max credits per minute: ${cpm(maxCreditsPerMinute)}');

  final maxCreditsPerTenMinutes = maxCreditsPerMinute * 10;
  logger.info('Max credits per 10m: ${c(maxCreditsPerTenMinutes)}');
}

void main(List<String> args) {
  runOffline(args, command);
}
