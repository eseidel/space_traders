import 'dart:io';

import 'package:file/file.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as p;
import 'package:space_gen/space_gen.dart';
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/spec.dart';
import 'package:space_gen/src/string.dart';

Template loadTemplate(FileSystem fs, String name) {
  // I'm not sure how to load a template relative to the package root
  // for when this is installed via pub.  I'm sure it's possible.
  return Template(
    fs.file('lib/templates/$name.mustache').readAsStringSync(),
    partialResolver: (s) => loadTemplate(fs, s),
    name: name,
  );
}

String _apiPath(Api api) {
  // openapi generator does not use /src/ in the path.
  return 'lib/api/${api.fileName}.dart';
}

String _modelPath(Schema schema) {
  // openapi generator does not use /src/ in the path.
  return 'lib/model/${schema.fileName}.dart';
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

extension SpecGeneration on Spec {
  List<Api> get apis =>
      tags
          .map(
            (tag) => Api(
              name: tag,
              endpoints: endpoints.where((e) => e.tag == tag).toList(),
            ),
          )
          .toList();
}

extension EndpointGeneration on Endpoint {
  String get methodName {
    final name = camelFromSnake(snakeName);
    return name[0].toLowerCase() + name.substring(1);
  }

  Uri uri(Context context) => Uri.parse('${context.spec.serverUrl}$path');

  Map<String, dynamic> toTemplateContext(Context context) {
    final parameters =
        this.parameters
            .map((param) => param.toTemplateContext(context))
            .toList();
    final body = context.maybeResolve(requestBody);
    if (body != null) {
      final typeName = body.typeName(context);
      final paramName = typeName[0].toLowerCase() + typeName.substring(1);
      parameters.add({
        'paramName': paramName,
        'paramType': typeName,
        'paramToJson': body.toJsonExpression(paramName, context),
        'paramFromJson': body.fromJsonExpression('json', context),
      });
    }
    final firstResponse = context.maybeResolve(responses.firstOrNull?.content);
    final returnType = firstResponse?.typeName(context) ?? 'void';
    return {
      'methodName': methodName,
      'httpMethod': method,
      'path': path,
      'url': uri(context),
      'parameters': parameters,
      'returnIsVoid': returnType == 'void',
      'returnType': returnType,
    };
  }
}

extension SchemaGeneration on Schema {
  String get fileName => snakeName;

  String get className => camelFromSnake(snakeName);

  bool get needsRender => type == SchemaType.object || isEnum;

  bool get isDateTime {
    return type == SchemaType.string && format == 'date-time';
  }

  bool get isEnum {
    return type == SchemaType.string && enumValues.isNotEmpty;
  }

  // Is a Map with a specified value type.
  Schema? valueSchema(Context context) {
    if (type != SchemaType.object) {
      return null;
    }
    return context.maybeResolve(additionalProperties);
  }

  String typeName(Context context) {
    switch (type) {
      case SchemaType.string:
        if (isDateTime) {
          return 'DateTime';
        } else if (isEnum) {
          return className;
        }
        return 'String';
      case SchemaType.integer:
        return 'int';
      case SchemaType.number:
        return 'double';
      case SchemaType.boolean:
        return 'bool';
      case SchemaType.object:
        return className;
      case SchemaType.array:
        final itemsSchema = context.maybeResolve(items)!;
        return 'List<${itemsSchema.typeName(context)}>';
      case SchemaType.unknown:
        return 'dynamic';
    }
    // throw UnimplementedError('Unknown type $type');
  }

  String toJsonExpression(String name, Context context) {
    switch (type) {
      case SchemaType.string:
        if (isDateTime) {
          return '$name.toIso8601String()';
        } else if (isEnum) {
          return '$name.toJson()';
        }
        return name;
      case SchemaType.integer:
      case SchemaType.number:
      case SchemaType.boolean:
        return name;
      case SchemaType.object:
        return '$name.toJson()';
      case SchemaType.array:
        final itemsSchema = context.maybeResolve(items)!;
        switch (itemsSchema.type) {
          case SchemaType.unknown:
          case SchemaType.string:
          case SchemaType.integer:
          case SchemaType.number:
          case SchemaType.boolean:
            // Don't call toJson on primitives.
            return name;
          case SchemaType.object:
          case SchemaType.array:
            return '$name.map((e) => e.toJson()).toList()';
        }
      case SchemaType.unknown:
        return name;
    }
  }

  String fromJsonExpression(String jsonValue, Context context) {
    switch (type) {
      case SchemaType.string:
        if (isDateTime) {
          return 'DateTime.parse($jsonValue as String)';
        } else if (isEnum) {
          return '$className.fromJson($jsonValue as String)';
        }
        return '$jsonValue as String';
      case SchemaType.integer:
        return '$jsonValue as int';
      case SchemaType.number:
        return '$jsonValue as double';
      case SchemaType.boolean:
        return '$jsonValue as bool';
      case SchemaType.object:
        return '$className.fromJson($jsonValue as Map<String, dynamic>)';
      case SchemaType.array:
        final itemsSchema = context.maybeResolve(items)!;
        final itemTypeName = itemsSchema.typeName(context);
        if (itemsSchema.type == SchemaType.object) {
          return '($jsonValue as List<dynamic>).map<$itemTypeName>((e) => '
              '$itemTypeName.fromJson(e as Map<String, dynamic>)).toList()';
        } else {
          return '($jsonValue as List<dynamic>).cast<$itemTypeName>()';
        }
      case SchemaType.unknown:
        return jsonValue;
    }
  }

  Map<String, dynamic> objectToTemplateContext(Context context) {
    final renderProperties = properties.entries.map((entry) {
      final name = entry.key;
      final schema = context.maybeResolve(entry.value)!;
      return {
        'propertyName': name,
        'propertyType': schema.typeName(context),
        'propertyToJson': schema.toJsonExpression(name, context),
        'propertyFromJson': schema.fromJsonExpression("json['$name']", context),
      };
    });
    final valueSchema = this.valueSchema(context);
    return {
      'schemaName': className,
      'hasProperties': renderProperties.isNotEmpty,
      'properties': renderProperties,
      'hasAdditionalProperties': valueSchema != null,
      'valueSchema': valueSchema?.typeName(context),
      'valueToJson': valueSchema?.toJsonExpression('value', context),
      'valueFromJson': valueSchema?.fromJsonExpression('value', context),
    };
  }

  Map<String, dynamic> _enumToTemplateContext() {
    Map<String, dynamic> enumValueToTemplateContext(String value) {
      var dartName = camelFromScreamingCaps(value);
      if (isReservedWord(dartName)) {
        dartName = '${dartName}_';
      }
      return {'enumValueName': dartName, 'enumValue': value};
    }

    return {
      'schemaName': className,
      'enumValues': enumValues.map(enumValueToTemplateContext).toList(),
    };
  }

  Map<String, dynamic> toTemplateContext(Context context) {
    if (isEnum) {
      return _enumToTemplateContext();
    } else {
      return objectToTemplateContext(context);
    }
  }

  String packageImport(Context context) {
    return 'package:${context.packageName}/model/$snakeName.dart';
  }
}

extension ParameterGeneration on Parameter {
  Map<String, dynamic> toTemplateContext(Context context) {
    final typeSchema = context.maybeResolve(type)!;
    return {
      'paramName': name,
      'paramType': typeSchema.typeName(context),
      'paramToJson': typeSchema.toJsonExpression(name, context),
      'paramFromJson': typeSchema.fromJsonExpression("json['$name']", context),
    };
  }
}

extension SchemaRefGeneration on SchemaRef {
  String packageImport(Context context) {
    final name = p.basenameWithoutExtension(uri!);
    final snakeName = snakeFromCamel(name);
    return 'package:${context.packageName}/model/$snakeName.dart';
  }
}

// Separate load context vs. render context?
class Context {
  Context({
    required this.specUrl,
    required this.spec,
    required this.outDir,
    required this.packageName,
    required this.fs,
    required this.schemaRegistry,
  });

  final Uri specUrl;
  final Spec spec;
  final Directory outDir;
  final String packageName;
  final FileSystem fs;
  final SchemaRegistry schemaRegistry;

  Schema? maybeResolve(SchemaRef? ref) {
    if (ref == null) {
      return null;
    }
    return resolve(ref);
  }

  Schema resolve(SchemaRef ref) {
    if (ref.schema != null) {
      return ref.schema!;
    }
    final uri = specUrl.resolve(ref.uri!);
    return schemaRegistry.get(uri);
  }

  File _ensureFile(String path) {
    final file = fs.file(p.join(outDir.path, path));
    file.parent.createSync(recursive: true);
    return file;
  }

  void writeFile({required String path, required String content}) {
    _ensureFile(path).writeAsStringSync(content);
  }

  void renderTemplate({
    required String template,
    required String outPath,
    Map<String, dynamic> context = const {},
  }) {
    final output = loadTemplate(fs, template).renderString(context);
    writeFile(path: outPath, content: output);
  }

  void renderDirectory() {
    outDir.createSync(recursive: true);
    renderTemplate(
      template: 'pubspec',
      outPath: 'pubspec.yaml',
      context: {'packageName': packageName},
    );
    renderTemplate(
      template: 'analysis_options',
      outPath: 'analysis_options.yaml',
    );
    renderTemplate(template: 'gitignore', outPath: '.gitignore');
  }

  void renderApis() {
    final rendered = <String>{};
    final renderQueue = <SchemaRef>{};
    for (final api in spec.apis) {
      final renderContext = RenderContext(specUri: specUrl);
      renderApi(renderContext, this, api);
      // Api files only contain the API class, any inline schemas
      // end up in the model files.
      for (final schema in renderContext.inlineSchemas) {
        renderRootSchema(this, schema);
      }
      renderQueue.addAll(renderContext.importedSchemas);
    }

    // Render all the schemas that were collected while rendering the API.
    while (renderQueue.isNotEmpty) {
      final ref = renderQueue.first;
      renderQueue.remove(ref);
      if (rendered.contains(ref.uri)) {
        continue;
      }
      rendered.add(ref.uri!);
      final schema = resolve(ref);
      final renderContext = renderRootSchema(this, schema);
      renderQueue.addAll(renderContext.importedSchemas);
    }
  }

  void runDart(List<String> args) {
    logger.detail('dart ${args.join(' ')} in ${outDir.path}');
    final result = Process.runSync('dart', args, workingDirectory: outDir.path);
    if (result.exitCode != 0) {
      logger.info(result.stderr as String);
      throw Exception('Failed to run dart ${args.join(' ')}');
    }
    logger.detail(result.stdout as String);
  }

  void renderPublicApi() {
    final exports =
        spec.apis
            .map((api) => 'package:$packageName/api/${api.fileName}.dart')
            .toList()
          ..sort();
    renderTemplate(
      template: 'public_api',
      outPath: 'lib/api.dart',
      context: {'imports': <String>[], 'exports': exports},
    );
  }

  void render() {
    renderDirectory();
    renderApis();
    // renderModels();
    renderPublicApi();
    runDart(['pub', 'get']);
    // Run format first to add missing commas.
    runDart(['format', '.']);
    // Then run fix to clean up various other things.
    runDart(['fix', '.', '--apply']);
    // Run format again to fix wrapping of lines.
    runDart(['format', '.']);
  }
}

/// This appears to be per-file rendering context which differs from Context
/// which is global for the entire render?
class RenderContext {
  RenderContext({required this.specUri});

  final Uri specUri;

  /// Schemas to render in this file.
  List<Schema> inlineSchemas = [];

  /// Schemas imported by this file.
  Set<SchemaRef> importedSchemas = {};

  void visitSchema(SchemaRef? ref) {
    if (ref == null) {
      return;
    }
    if (ref.schema != null) {
      collectSchema(ref.schema!);
    } else {
      importedSchemas.add(ref);
    }
  }

  void collectApi(Api api) {
    for (final endpoint in api.endpoints) {
      for (final response in endpoint.responses) {
        visitSchema(response.content);
      }
      for (final param in endpoint.parameters) {
        visitSchema(param.type);
      }
      if (endpoint.requestBody != null) {
        visitSchema(endpoint.requestBody);
      }
    }
  }

  void collectSchema(Schema schema) {
    if (schema.needsRender) {
      inlineSchemas.add(schema);
    }
    for (final entry in schema.properties.entries) {
      visitSchema(entry.value);
    }
    if (schema.type == SchemaType.array) {
      visitSchema(schema.items);
    }
  }

  List<String> sortedPackageImports(
    Context context, {
    bool includeInlineSchema = false,
  }) {
    final imports = <String>{};
    for (final ref in importedSchemas) {
      imports.add(ref.packageImport(context));
    }
    if (includeInlineSchema) {
      for (final schema in inlineSchemas) {
        imports.add(schema.packageImport(context));
      }
    }
    return imports.toList()..sort();
  }

  List<Map<String, dynamic>> objectContexts(Context context) {
    return inlineSchemas
        .where((schema) => schema.type == SchemaType.object)
        .map((schema) => schema.toTemplateContext(context))
        .toList();
  }

  List<Map<String, dynamic>> enumContexts(Context context) {
    return inlineSchemas
        .where((schema) => schema.isEnum)
        .map((schema) => schema.toTemplateContext(context))
        .toList();
  }
}

/// Starts a new RenderContext for rendering a new schema file.
RenderContext renderRootSchema(Context context, Schema schema) {
  // logger.info('Rendering ${schema.name}');

  final renderContext = RenderContext(specUri: context.specUrl)
    ..collectSchema(schema);
  // logger
  //   ..info('To import: ${renderContext.imported}')
  //   ..info('To render: ${renderContext.inlineSchemas}');

  final imports = renderContext.sortedPackageImports(context);
  final objects = renderContext.objectContexts(context);
  final enums = renderContext.enumContexts(context);

  context.renderTemplate(
    template: 'model',
    outPath: _modelPath(schema),
    context: {'imports': imports, 'objects': objects, 'enums': enums},
  );
  return renderContext;
}

void renderApi(RenderContext renderContext, Context context, Api api) {
  final endpoints =
      api.endpoints.map((e) => e.toTemplateContext(context)).toList();
  renderContext.collectApi(api);

  final imports = renderContext.sortedPackageImports(
    context,
    includeInlineSchema: true,
  );

  // The OpenAPI generator only includes the APIs in the api/ directory
  // all other classes and enums go in the model/ directory even ones
  // which were defined inline in the main spec.
  context.renderTemplate(
    template: 'api',
    outPath: _apiPath(api),
    context: {
      'className': api.className,
      'imports': imports,
      'endpoints': endpoints,
    },
  );
}
