import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as p;
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/render_tree.dart';
import 'package:space_gen/src/resolver.dart';
import 'package:space_gen/src/string.dart';
import 'package:space_gen/src/types.dart';

String avoidReservedWord(String value) {
  if (isReservedWord(value)) {
    return '${value}_';
  }
  return value;
}

Never _unimplemented(String message, String pointer) {
  throw UnimplementedError('$message at $pointer');
}

/// A convenience class created for each operation within a path item
/// for compatibility with our existing rendering code.
class Endpoint {
  const Endpoint({required this.operation, required this.serverUrl});

  /// The server url of the endpoint.
  final Uri serverUrl;

  /// The operation of the endpoint.
  final RenderOperation operation;

  /// The method of the endpoint.
  Method get method => operation.method;

  String get path => operation.path;

  String get tag => operation.tags.firstOrNull ?? 'Default';

  String get snakeName => operation.snakeName;

  List<RenderParameter> get parameters => operation.parameters;

  String get methodName => lowercaseCamelFromSnake(snakeName);

  Uri get uri => Uri.parse('$serverUrl$path');

  Map<String, dynamic> toTemplateContext(SchemaRenderer context) {
    final serverParameters = parameters.map((param) {
      return param.toTemplateContext(context);
    }).toList();

    final requestBody = operation.requestBody?.toTemplateContext(context);
    // Parameters as passed to the Dart function call, including the request
    // body if it exists.
    final dartParameters = [...serverParameters, ?requestBody];

    final responseSchema = operation.responses.first.content;
    final returnType = responseSchema.typeName(context);
    final responseFromJson = responseSchema.fromJsonExpression(
      'jsonDecode(response.body)',
      context,
      jsonIsNullable: false,
      dartIsNullable: false,
    );

    final namedParameters = dartParameters.where((p) => p['required'] == false);
    final positionalParameters = dartParameters.where(
      (p) => p['required'] == true,
    );

    // TODO(eseidel): This grouping should happen before converting to
    // template context while we still have strong types.
    final bySendIn = serverParameters.groupListsBy((p) => p['sendIn']);

    final pathParameters = bySendIn['path'] ?? [];
    final queryParameters = bySendIn['query'] ?? [];
    final hasQueryParameters = queryParameters.isNotEmpty;
    final cookieParameters = bySendIn['cookie'] ?? [];
    if (cookieParameters.isNotEmpty) {
      _unimplemented('Cookie parameters are not yet supported.', path);
    }
    final headerParameters = bySendIn['header'] ?? [];
    final hasHeaderParameters = headerParameters.isNotEmpty;

    return {
      'methodName': methodName,
      'httpMethod': method.name,
      'path': path,
      'url': uri,
      // Parameters grouped for dart parameter generation.
      'positionalParameters': positionalParameters,
      'hasNamedParameters': namedParameters.isNotEmpty,
      'namedParameters': namedParameters,
      // Parameters grouped for call to server.
      'pathParameters': pathParameters,
      'hasQueryParameters': hasQueryParameters,
      'queryParameters': queryParameters,
      'hasHeaderParameters': hasHeaderParameters,
      'headerParameters': headerParameters,
      'requestBody': requestBody,
      'returnType': returnType,
      'responseFromJson': responseFromJson,
    };
  }
}

/// The spec calls these tags, but the Dart openapi generator groups endpoints
/// by tag into an API class so we do too.
class Api {
  const Api({required this.name, required this.endpoints});

  final String name;
  final List<Endpoint> endpoints;

  String get className => '${name.capitalize()}Api';
  String get fileName => '${name.toLowerCase()}_api';
}

enum SchemaRenderType { enumeration, object, stringNewtype, numberNewtype, pod }

typedef RunProcess =
    ProcessResult Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
    });

class TemplateProvider {
  TemplateProvider.fromDirectory(this.templateDir) {
    if (!templateDir.existsSync()) {
      throw Exception('Template directory does not exist: ${templateDir.path}');
    }
  }

  TemplateProvider.defaultLocation()
    : templateDir = const LocalFileSystem().directory('lib/templates');

  final Directory templateDir;

  Template loadTemplate(String name) {
    return Template(
      templateDir.childFile('$name.mustache').readAsStringSync(),
      partialResolver: loadTemplate,
      name: name,
    );
  }
}

class FileRenderer {
  FileRenderer({
    required this.outDir,
    required this.packageName,
    required this.templateProvider,
    RunProcess? runProcess,
    this.quirks = const Quirks(),
  }) : fs = outDir.fileSystem,
       runProcess = runProcess ?? Process.runSync;

  /// The output directory.
  final Directory outDir;

  /// The package name this spec is being rendered into.
  final String packageName;

  /// The provider of templates.
  final TemplateProvider templateProvider;

  /// The file system where the rendered files will go.
  final FileSystem fs;

  /// The function to run a process. Allows for mocking in tests.
  final RunProcess runProcess;

  /// The quirks to use for rendering.
  final Quirks quirks;

  /// The path to the api file.
  static String apiFilePath(Api api) {
    // openapi generator does not use /src/ in the path.
    return 'lib/api/${api.fileName}.dart';
  }

  static String apiPackagePath(Api api) {
    return 'api/${api.fileName}.dart';
  }

  static String modelFilePath(RenderSchema schema) {
    // openapi generator does not use /src/ in the path.
    return 'lib/model/${schema.snakeName}.dart';
  }

  static String modelPackagePath(RenderSchema schema) {
    return 'model/${schema.snakeName}.dart';
  }

  String packageImport(FileRenderer context, RenderSchema schema) {
    return 'package:${context.packageName}/model/${schema.snakeName}.dart';
  }

  // String packageImport(_Context context) {
  //   final name = p.basenameWithoutExtension(ref!);
  //   final snakeName = snakeFromCamel(name);
  //   return 'package:${context.packageName}/model/$snakeName.dart';
  // }

  /// Ensure a file exists.
  File _ensureFile(String path) {
    final file = fs.file(p.join(outDir.path, path));
    file.parent.createSync(recursive: true);
    return file;
  }

  /// Write a file.
  void _writeFile({required String path, required String content}) {
    _ensureFile(path).writeAsStringSync(content);
  }

  /// Render a template.
  void _renderTemplate({
    required String template,
    required String outPath,
    Map<String, dynamic> context = const {},
  }) {
    final output = templateProvider
        .loadTemplate(template)
        .renderString(context);
    _writeFile(path: outPath, content: output);
  }

  /// Render the package directory including
  /// pubspec, analysis_options, and gitignore.
  void _renderDirectory() {
    outDir.createSync(recursive: true);
    _renderTemplate(
      template: 'pubspec',
      outPath: 'pubspec.yaml',
      context: {'packageName': packageName},
    );
    _renderTemplate(
      template: 'analysis_options',
      outPath: 'analysis_options.yaml',
      context: {
        'mutableModels': quirks.mutableModels,
        'screamingCapsEnums': quirks.screamingCapsEnums,
      },
    );
    _renderTemplate(template: 'gitignore', outPath: '.gitignore');
  }

  /// Render the api client.
  void _renderApiClient({required RenderSpec spec}) {
    _renderTemplate(
      template: 'api_exception',
      outPath: 'lib/api_exception.dart',
    );
    _renderTemplate(
      template: 'api_client',
      outPath: 'lib/api_client.dart',
      context: {'baseUri': spec.serverUrl, 'packageName': packageName},
    );
    _renderTemplate(
      template: 'model_helpers',
      outPath: 'lib/model_helpers.dart',
    );
  }

  /// Run a dart command.
  void _runDart(List<String> args) {
    logger.detail('dart ${args.join(' ')} in ${outDir.path}');
    final result = runProcess(
      Platform.executable,
      args,
      workingDirectory: outDir.path,
    );
    if (result.exitCode != 0) {
      logger.info(result.stderr as String);
      throw Exception('Failed to run dart ${args.join(' ')}');
    }
    logger.detail(result.stdout as String);
  }

  /// Render the public API file.
  void _renderPublicApi(List<Api> apis, List<RenderSchema> schemas) {
    final paths = [
      ...apis.map(apiPackagePath),
      ...schemas.map(modelPackagePath),
      'api_client.dart',
      'api_exception.dart',
    ];
    final exports = paths
        .map((path) => 'package:$packageName/$path')
        .sorted()
        .toList();
    _renderTemplate(
      template: 'public_api',
      outPath: 'lib/api.dart',
      context: {'imports': <String>[], 'exports': exports},
    );
  }

  /// Render the entire spec.
  void render({
    required RenderSpec spec,
    required SchemaRenderer schemaRenderer,
  }) {
    // Collect all the Apis and Model Schemas.
    // Do we walk through each endpoint and ask which class to put it on?
    // Do we then walk through each class and ask what file to put it in?
    // Then we walk through all model objects and ask what file to put them in?
    // And then for each rendered we collect any imports, by asking for the
    // file path for each referenced schema?
    final apis = spec.apis;
    final schemas = collectModelSchemas(spec);

    // Set up the package directory.
    _renderDirectory();
    for (final api in apis) {
      final content = schemaRenderer.renderApi(api);
      // final referencedSchemas = collectSchemasFromApi(api);
      // import 'dart:async';
      // import 'dart:convert';

      // import 'package:{{{packageName}}}/api_client.dart';
      // import 'package:http/http.dart' as http;
      // {{#imports}}
      // import '{{{.}}}';
      // {{/imports}}

      final outPath = apiFilePath(api);
      _writeFile(path: outPath, content: content);
    }
    for (final schema in schemas) {
      if (schema is RenderVoid ||
          schema is RenderUnknown ||
          schema is RenderArray ||
          schema is RenderPod) {
        continue;
      }

      final content = schemaRenderer.renderSchema(schema);
      // final referencedSchemas = collectSchemasFromModel(schema);
      final outPath = modelFilePath(schema);
      _writeFile(path: outPath, content: content);
    }
    _renderApiClient(spec: spec);
    // Render the combined api.dart exporting all rendered schemas.
    _renderPublicApi(apis, schemas);
    // Consider running pub upgrade here to ensure packages are up to date.
    // Might need to make offline configurable?
    _runDart(['pub', 'get', '--offline']);
    // Run format first to add missing commas.
    _runDart(['format', '.']);
    // Then run fix to clean up various other things.
    _runDart(['fix', '.', '--apply']);
    // Run format again to fix wrapping of lines.
    _runDart(['format', '.']);
  }
}

/// Context for rendering the spec.
class SchemaRenderer {
  /// Create a new context for rendering the spec.
  SchemaRenderer({
    required this.specUrl,
    required this.spec,
    required this.templateProvider,
    this.quirks = const Quirks(),
  });

  /// The url of the spec being rendered.  Used for resolving relative urls.
  final Uri specUrl;

  /// The spec being rendered.
  final RenderSpec spec;

  /// The provider of templates.
  final TemplateProvider templateProvider;

  /// The quirks to use for rendering.
  final Quirks quirks;

  /// The type of the json object passed to fromJson.
  String get fromJsonJsonType =>
      quirks.dynamicJson ? 'dynamic' : 'Map<String, dynamic>';

  /// Renders a schema to a string, does not render the imports.
  String renderSchema(RenderSchema schema) {
    final Map<String, dynamic> schemaContext;
    final String template;
    switch (schema) {
      case RenderEnum():
        schemaContext = schema.toTemplateContext(this);
        template = 'schema_enum';
      case RenderObject():
        schemaContext = schema.toTemplateContext(this);
        template = 'schema_object';
      case RenderStringNewType():
        schemaContext = schema.toTemplateContext(this);
        template = 'schema_string_newtype';
      case RenderNumberNewType():
        schemaContext = schema.toTemplateContext(this);
        template = 'schema_number_newtype';
      case RenderPod():
        throw StateError('Pod schemas should not be rendered: $schema');
      default:
        throw StateError('Unknown schema: $schema');
    }

    return templateProvider.loadTemplate(template).renderString(schemaContext);
  }

  /// Renders an api to a string, does not render the imports.
  String renderApi(Api api) {
    final endpoints = api.endpoints
        .map((e) => e.toTemplateContext(this))
        .toList();

    // The OpenAPI generator only includes the APIs in the api/ directory
    // all other classes and enums go in the model/ directory even ones
    // which were defined inline in the main spec.
    return templateProvider.loadTemplate('api').renderString({
      'className': api.className,
      'endpoints': endpoints,
    });
  }
}

/// Quirks are a set of flags that can be used to customize the generated code.
class Quirks {
  const Quirks({
    this.dynamicJson = false,
    this.mutableModels = false,
    // Avoiding ever having List? seems reasonable so we default to true.
    this.allListsDefaultToEmpty = true,
    this.nonNullableDefaultValues = false,
    this.screamingCapsEnums = false,
  });

  const Quirks.openapi()
    : this(
        dynamicJson: true,
        mutableModels: true,
        nonNullableDefaultValues: true,
        allListsDefaultToEmpty: true,
        screamingCapsEnums: true,
      );

  /// Use "dynamic" instead of "Map\<String, dynamic\>" for passing to fromJson
  /// to match OpenAPI's behavior.
  final bool dynamicJson;

  /// Use mutable models instead of immutable ones to match OpenAPI's behavior.
  final bool mutableModels;

  /// OpenAPI seems to have the behavior whereby all Lists default to empty
  /// lists.
  final bool allListsDefaultToEmpty;

  /// OpenAPI seems to have the behavior whereby if a property has a default
  /// value it can never be nullable.  Since OpenAPI also makes all Lists
  /// default to empty lists, this means that all Lists are non-nullable.
  final bool nonNullableDefaultValues;

  /// OpenAPI uses SCREAMING_CAPS for enum values, but that's not Dart style.
  final bool screamingCapsEnums;

  // Potential future quirks:

  /// OpenAPI flattens everything into the top level `lib` folder.
  // final bool doNotUseSrcPaths;
}

void renderSpec({
  required Uri specUri,
  required String packageName,
  required Directory outDir,
  required ResolvedSpec spec,
  Directory? templateDir,
  RunProcess? runProcess,
  Quirks quirks = const Quirks(),
}) {
  // TODO(eseidel): split the determination of which schemas go into what
  // files out from the production of the code.

  final templateProvider = TemplateProvider.fromDirectory(
    templateDir ?? const LocalFileSystem().directory('lib/templates'),
  );

  final fileRenderer = FileRenderer(
    outDir: outDir,
    packageName: packageName,
    templateProvider: templateProvider,
    runProcess: runProcess,
    quirks: quirks,
  );
  final renderSpec = toRenderSpec(spec);
  final schemaRenderer = SchemaRenderer(
    specUrl: specUri,
    spec: renderSpec,
    templateProvider: templateProvider,
    quirks: quirks,
  );
  fileRenderer.render(spec: renderSpec, schemaRenderer: schemaRenderer);
}
