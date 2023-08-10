import 'dart:io';

import 'package:args/args.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/counts.dart';
import 'package:cli/net/queue.dart';
import 'package:cli/printing.dart';
import 'package:file/local.dart';
import 'package:postgres/postgres.dart';
import 'package:scoped/scoped.dart';

void printRequestStats(RequestCounts requestCounts) {
  final counts = requestCounts.counts;
  final generalizedCounts = <String, int>{};
  for (final key in counts.keys) {
    final generalizedKey =
        key.split('/').map((part) => part.contains('-') ? 'N' : part).join('/');
    generalizedCounts[generalizedKey] =
        (generalizedCounts[generalizedKey] ?? 0) + counts[key]!;
  }
  // print the counts in order of most to least.
  final sortedCounts = generalizedCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  logger.info('Request stats:');
  for (final entry in sortedCounts) {
    logger.info('${entry.value} ${entry.key}');
  }
  logger.info('Total: ${requestCounts.totalRequests()} requests.');
}

bool Function(Ship ship)? _shipFilterFromArgs(Agent agent, List<String> only) {
  if (only.isEmpty) {
    return null;
  }
  final onlyShips =
      only.map((s) => ShipSymbol(agent.symbol, int.parse(s, radix: 16)));
  if (onlyShips.isNotEmpty) {
    logger.info('Only running ships: $onlyShips');
  }
  return (Ship ship) => onlyShips.contains(ship.shipSymbol);
}

Api getApi(
  String token,
  PostgreSQLConnection? connection,
) {
  // TODO(eseidel): This is wrong.  This needs to check that
  // that there is a network executor running, not just that we have
  // a connection to the database.
  if (connection == null) {
    return apiFromAuthToken(token, ClientType.localLimits);
  }
  final api = apiFromAuthToken(token, ClientType.unlimited);
  final queuedClient = QueuedClient(connection)..getPriority = () => 0;
  api.apiClient.client = queuedClient;
  return api;
}

Future<void> cliMain(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose logging.')
    ..addFlag(
      'local',
      abbr: 'l',
      negatable: false,
      help: 'Use in-process rate limiting instead of database queue.',
    )
    ..addMultiOption(
      'only',
      abbr: 'o',
      help: 'Only run the given ship numbers (hex).',
    );
  final results = parser.parse(args);

  logger.level = results['verbose'] as bool ? Level.verbose : Level.info;

  logger.info('Welcome to Space Traders! 🚀');
  // Use package:file to make things mockable.
  const fs = LocalFileSystem();

  final env = Platform.environment;
  final callsign = env['SPACETRADERS_CALLSIGN'];
  final email = env['SPACETRADERS_EMAIL'];
  final token =
      await loadAuthTokenOrRegister(fs, callsign: callsign, email: email);

  final useOutOfProcessNetwork = !(results['local'] as bool);
  final dbConnection = useOutOfProcessNetwork ? await defaultDatabase() : null;
  final api = getApi(token, dbConnection);

  final caches = await Caches.load(fs, api);
  logger.info(
    'Loaded ${caches.marketPrices.count} prices from '
    '${caches.marketPrices.waypointCount} markets and '
    '${caches.shipyardPrices.count} prices from '
    '${caches.shipyardPrices.waypointCount} shipyards.',
  );
  final centralCommand =
      CentralCommand(behaviorCache: caches.behaviors, shipCache: caches.ships);

  final status = await api.defaultApi.getStatus();
  printStatus(status!);

  // Handle ctrl-c and print out request stats.
  // This should be made an argument rather than on by default.
  ProcessSignal.sigint.watch().listen((signal) {
    printRequestStats(api.requestCounts);
    exit(0);
  });

  final agent = caches.agent.agent;
  logger
    ..info(
      'Welcome ${agent.symbol} of the ${agent.startingFaction}!'
      ' ${creditsString(agent.credits)}',
    )
    ..info(describeFleet(caches.ships));

  // We use defaultTo: [], so we don't have to check fo null here.
  // This means that we won't notice `--only` being passed with no ships.
  // But that's also OK since that's nonsentical.
  final shipFilter =
      _shipFilterFromArgs(agent, results['only'] as List<String>);
  await logic(api, centralCommand, caches, shipFilter: shipFilter);
}

Future<void> main(List<String> args) async {
  await runScoped(
    () async {
      await cliMain(args);
    },
    values: {loggerRef},
  );
}
