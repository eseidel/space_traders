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
Future<R> runOffline<R>(
  List<String> args,
  Future<R> Function(FileSystem fs, ArgResults argResults) fn, {
  void Function(ArgParser parser)? addArgs,
}) async {
  final parser = ArgParser()
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose logging',
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
      return fn(fs, results);
    },
    values: {loggerRef},
  );
}
