import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:space_gen/space_gen.dart';
import 'package:space_gen/src/config.dart';
import 'package:space_gen/src/loader.dart';
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/resolver.dart';

Future<int> main(List<String> arguments) async {
  const fs = LocalFileSystem();
  // Mostly trying to match openapi-generator-cli
  final parser =
      ArgParser()..addOption('config', abbr: 'c', help: 'Path to config file');
  final results = parser.parse(arguments);
  if (results.rest.isNotEmpty) {
    logger
      ..err('Unexpected arguments: ${results.rest}')
      ..info(parser.usage);
    return 1;
  }

  final configPath = results['config'] as String?;
  final Config config;
  if (configPath != null) {
    config = loadFromFile(fs.file(configPath));
  } else {
    logger
      ..err('No config file provided')
      ..info(parser.usage);
    return 1;
  }

  final specPath = config.specUri;
  final outDir = config.outDir;
  logger.info('Generating $specPath to ${outDir.path}');

  // Could make clearing of the directory optional.
  if (outDir.existsSync()) {
    outDir.deleteSync(recursive: true);
  }

  // First we want to load the spec.
  // Then we want to walk and resolve all the references.
  // Then we hand a fully resolved spec to the renderer.

  final cache = Cache(fs);
  final spec = await cache.loadSpec(config.specUri);

  // Print stats about the spec.
  logger.info('Spec:');
  for (final api in spec.tags) {
    logger.info('  - $api');
    final endpoints = spec.endpoints.where((e) => e.tag == api);
    for (final endpoint in endpoints) {
      logger.info('    - ${endpoint.method.key} ${endpoint.path}');
    }
  }

  await cache.precacheRefs(config.specUri, spec);

  final resolver = Resolver(fs, config.specUri, cache);
  final resolvedSpec = resolver.resolveSpec(spec);

  Context(
    spec: resolvedSpec,
    specUrl: config.specUri,
    fs: fs,
    outDir: outDir,
    packageName: config.packageName,
  ).render();
  return 0;
}
