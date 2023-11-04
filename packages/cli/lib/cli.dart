import 'package:args/args.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:file/local.dart';
import 'package:scoped/scoped.dart';

export 'package:args/args.dart';
export 'package:cli/logger.dart';
export 'package:db/db.dart';
export 'package:file/file.dart';
export 'package:types/types.dart';

/// This file should be included by any bin/ script.

/// Run command with a logger, but without an Api.
Future<void> runOffline(
  List<String> args,
  Future<void> Function(FileSystem fs, ArgResults argResults) fn, {
  void Function(ArgParser parser)? addArgs,
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
      return fn(fs, results);
    },
    values: {loggerRef},
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
