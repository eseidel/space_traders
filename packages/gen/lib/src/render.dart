import 'package:file/file.dart';
import 'package:space_gen/src/context.dart';
import 'package:space_gen/src/loader.dart';
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/parser.dart';
import 'package:space_gen/src/resolver.dart';

Future<void> loadAndRenderSpec({
  required Uri specUri,
  required String packageName,
  required Directory outDir,
  Directory? templateDir,
  RunProcess? runProcess,
  Quirks quirks = const Quirks(),
}) async {
  final fs = outDir.fileSystem;

  // Load the spec and warm the cache before rendering.
  final cache = Cache(fs);
  final specJson = await cache.load(specUri);
  final spec = parseOpenApi(specJson);

  // TODO(eseidel): Re-enable this when we have a multi-file example spec.
  // Pre-warm the cache. Rendering assumes all refs are present in the cache.
  // for (final ref in collectRefs(spec)) {
  //   // If any of the refs are network urls, we need to fetch them.
  //   // The cache does not handle fragments, so we need to remove them.
  //   final resolved = specUri.resolve(ref).removeFragment();
  //   await cache.load(resolved);
  // }

  final resolved = resolveSpec(spec);
  logger.info('Generating $specUri to ${outDir.path}');

  // Could make clearing of the directory optional.
  if (outDir.existsSync()) {
    outDir.deleteSync(recursive: true);
  }

  renderSpec(
    spec: resolved,
    specUri: specUri,
    outDir: outDir,
    packageName: packageName,
    templateDir: templateDir,
    runProcess: runProcess,
    quirks: quirks,
  );
}
