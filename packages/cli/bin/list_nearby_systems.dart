import 'package:args/args.dart';
import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:file/local.dart';

void main(List<String> args) async {
  // Walk out to some number of jumps.
  // Return the number of waypoints that are mapped.

  final parser = ArgParser()
    ..addOption(
      'jumps',
      abbr: 'j',
      help: 'Maximum number of jumps to walk out',
      defaultsTo: '10',
    )
    ..addOption(
      'start',
      abbr: 's',
      help: 'Starting system (defaults to agent headquarters)',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose logging',
      negatable: false,
    );
  final results = parser.parse(args);
  final maxJumps = int.parse(results['jumps'] as String);
  if (results['verbose'] as bool) {
    setVerboseLogging();
  }

  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = SystemsCache.loadFromCache(fs)!;

  SystemWaypoint start;
  final startArg = results['start'] as String?;
  if (startArg != null) {
    final maybeStart = systemsCache.waypointOrNull(startArg);
    if (maybeStart == null) {
      logger.err('--start was invalid, unknown system: ${results['start']}');
      return;
    }
    start = maybeStart;
  } else {
    final agentCache = await AgentCache.load(api);
    start = agentCache.headquarters(systemsCache);
  }

  for (final (systemSymbol, jumps) in systemsCache.systemSymbolsInJumpRadius(
    startSystem: start.systemSymbol,
    maxJumps: maxJumps,
  )) {
    logger.info('$systemSymbol at $jumps jumps');
  }
}
