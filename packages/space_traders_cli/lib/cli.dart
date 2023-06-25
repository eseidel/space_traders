import 'package:args/args.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:file/local.dart';
import 'package:scoped/scoped.dart';

/// Run command with a logger.
Future<R> run<R>(
  List<String> args,
  Future<R> Function(FileSystem fs, Api api, Caches caches) fn,
) async {
  final parser = ArgParser()
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose logging',
      negatable: false,
    );
  final results = parser.parse(args);
  if (results['verbose'] as bool) {
    setVerboseLogging();
  }
  const fs = LocalFileSystem();
  return runScoped(
    () async {
      final api = defaultApi(fs);
      final caches = await Caches.load(fs, api);
      return fn(fs, api, caches);
    },
    values: {loggerRef},
  );
}
