import 'package:args/args.dart';
import 'package:cli_client/logger.dart';
// ignore:depend_on_referenced_packages
import 'package:client/client.dart';
import 'package:meta/meta.dart';
import 'package:scoped_deps/scoped_deps.dart';

export 'package:args/args.dart';
export 'package:cli_client/logger.dart';
export 'package:types/types.dart';

/// Run command with a logger, but without an Api.
Future<void> runAsClient(
  List<String> args,
  Future<void> Function(BackendClient client, ArgResults argResults) fn, {
  void Function(ArgParser parser)? addArgs,
  @visibleForTesting Logger? overrideLogger,
}) async {
  final parser =
      ArgParser()
        ..addFlag(
          'verbose',
          abbr: 'v',
          help: 'Verbose logging',
          negatable: false,
        )
        ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);
  addArgs?.call(parser);
  final results = parser.parse(args);
  return runScoped(
    () async {
      if (results['verbose'] as bool) {
        setVerboseLogging();
      }
      if (results['help'] as bool) {
        logger.info(parser.usage);
        return;
      }
      final client = BackendClient(
        hostedUri: Uri.parse('http://127.0.0.1:8080'),
      );
      final result = await fn(client, results);
      client.close();
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
