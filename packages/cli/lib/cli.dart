import 'package:args/args.dart';
import 'package:cli/caches.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:scoped/scoped.dart';
import 'package:types/types.dart';

export 'package:args/args.dart';
export 'package:cli/logger.dart';
export 'package:db/db.dart';
export 'package:file/file.dart';
export 'package:types/types.dart';

/// This file should be included by any bin/ script.

/// Run command with a logger, but without an Api.
Future<void> runOffline(
  List<String> args,
  Future<void> Function(FileSystem fs, Database db, ArgResults argResults) fn, {
  void Function(ArgParser parser)? addArgs,
  @visibleForTesting Logger? overrideLogger,
  @visibleForTesting Database? overrideDatabase,
}) async {
  final parser = ArgParser()
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose logging',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show help',
      negatable: false,
    );
  addArgs?.call(parser);
  final results = parser.parse(args);
  const fs = LocalFileSystem();
  return runScoped(
    () async {
      if (results['verbose'] as bool) {
        setVerboseLogging();
      }
      if (results['help'] as bool) {
        logger.info(parser.usage);
        return;
      }
      final db = overrideDatabase ?? await defaultDatabase();
      final result = await fn(fs, db, results);
      await db.close();
      return result;
    },
    values: {
      if (overrideLogger == null)
        loggerRef
      else
        loggerRef.overrideWith(() => overrideLogger),
    },
  );
}

/// Get a ship type from a command line argument.
ShipType shipTypeFromArg(String arg) {
  final upper = arg.toUpperCase();
  final name = upper.startsWith('SHIP_') ? upper : 'SHIP_$upper';
  return ShipType.values.firstWhere((e) => e.value == name);
}

/// Get a command line argument from a ship type.
String argFromShipType(ShipType shipType) {
  return shipType.value.substring('SHIP_'.length);
}

/// Common lookups which CLIs might need.

/// Get the agent from the database.
Future<Agent> myAgent(Database db) async {
  final agent = await db.getAgent(symbol: config.agentSymbol);
  return agent!;
}

/// Get the symbol of the agent's headquarters.
Future<WaypointSymbol> myHqSymbol(Database db) async {
  final agent = await myAgent(db);
  return agent.headquarters;
}

/// Get the system symbol of the agent's headquarters.
Future<SystemSymbol> myHqSystemSymbol(Database db) async {
  final hq = await myHqSymbol(db);
  return hq.system;
}

/// Get the agent's credits.
Future<int> myCredits(Database db) async {
  final agent = await myAgent(db);
  return agent.credits;
}

/// Get the start symbol from the command line argument.
Future<WaypointSymbol> startWaypointFromArg(Database db, String? arg) async {
  if (arg == null) {
    return myHqSymbol(db);
  }
  return WaypointSymbol.fromString(arg);
}

/// Get the start system from the command line argument.
Future<SystemSymbol> startSystemFromArg(Database db, String? arg) async {
  if (arg == null) {
    return myHqSystemSymbol(db);
  }
  return SystemSymbol.fromString(arg);
}

/// Shortcut for loading system connectivity when you don't care
/// about holding onto the jump gate snapshot or construction snapshot.
Future<SystemConnectivity> loadSystemConnectivity(Database db) async {
  final jumpGateSnapshot = await JumpGateSnapshot.load(db);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateSnapshot, constructionSnapshot);
  return systemConnectivity;
}
