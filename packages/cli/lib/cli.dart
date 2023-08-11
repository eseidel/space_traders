import 'package:args/args.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:file/local.dart';
import 'package:scoped/scoped.dart';

export 'package:cli/logger.dart';
export 'package:file/file.dart';

/// Run command with a logger, but without an Api.
Future<R> runOffline<R>(
  List<String> args,
  Future<R> Function(FileSystem fs, List<String> args) fn,
) async {
  final parser = ArgParser()
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose logging',
      negatable: false,
    );
  final results = parser.parse(args);
  const fs = LocalFileSystem();
  return runScoped(
    () async {
      if (results['verbose'] as bool) {
        setVerboseLogging();
      }
      return fn(fs, results.rest);
    },
    values: {loggerRef},
  );
}
