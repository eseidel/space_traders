import 'dart:io';

import 'package:file/file.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as p;
import 'package:space_gen/space_gen.dart';
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/resolver.dart';
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

String _modelPath(ResolvedSchema schema) {
  // openapi generator does not use /src/ in the path.
  return 'lib/model/${schema.fileName}.dart';
}

/// The spec calls these tags, but the Dart openapi generator groups endpoints
/// by tag into an API class so we do too.
class Api {
  const Api({required this.name, required this.endpoints});

  final String name;
  final List<ResolvedEndpoint> endpoints;

  String get className => '${name.capitalize()}Api';
  String get fileName => '${name.toLowerCase()}_api';
}

extension ResolvedSpecGeneration on ResolvedSpec {
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

extension EndpointGeneration on ResolvedEndpoint {
  String get methodName {
    final name = snakeName.splitMapJoin(
      '-',
      onMatch: (m) => '',
      onNonMatch: (n) => n.capitalize(),
    );
    return name[0].toLowerCase() + name.substring(1);
  }

  Uri uri(Context context) => Uri.parse('${context.spec.serverUrl}$path');

  Map<String, dynamic> toTemplateContext(Context context) {
    final parameters =
        this.parameters.map((param) => param.toTemplateContext()).toList();
    final body = requestBody;
    if (body != null) {
      final typeName = body.typeName();
      final paramName = typeName[0].toLowerCase() + typeName.substring(1);
      parameters.add({
        'paramName': paramName,
        'paramType': typeName,
        'paramToJson': body.toJsonExpression(paramName),
        'paramFromJson': body.fromJsonExpression('json'),
      });
    }
    return {
      'methodName': methodName,
      'httpMethod': method,
      'path': path,
      'url': uri(context),
      'parameters': parameters,
      'returnType': responses.first.content.typeName(),
    };
  }
}

extension SchemaGeneration on ResolvedSchema {
  String get fileName => snakeFromCamel(name);

  bool get needsRender => type == SchemaType.object || isEnum;

  bool get isDateTime {
    return type == SchemaType.string && format == 'date-time';
  }

  bool get isEnum {
    return type == SchemaType.string && enumValues.isNotEmpty;
  }

  String typeName() {
    switch (type) {
      case SchemaType.string:
        if (isDateTime) {
          return 'DateTime';
        } else if (isEnum) {
          return name;
        }
        return 'String';
      case SchemaType.integer:
        return 'int';
      case SchemaType.number:
        return 'double';
      case SchemaType.boolean:
        return 'bool';
      case SchemaType.object:
        return name;
      case SchemaType.array:
        return 'List<${items!.typeName()}>';
    }
    // throw UnimplementedError('Unknown type $type');
  }

  String toJsonExpression(String name) {
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
        final itemsSchema = items!;
        switch (itemsSchema.type) {
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
    }
  }

  String fromJsonExpression(String jsonValue) {
    switch (type) {
      case SchemaType.string:
        if (isDateTime) {
          return 'DateTime.parse($jsonValue as String)';
        } else if (isEnum) {
          return '$name.fromJson($jsonValue as String)';
        }
        return '$jsonValue as String';
      case SchemaType.integer:
        return '$jsonValue as int';
      case SchemaType.number:
        return '$jsonValue as double';
      case SchemaType.boolean:
        return '$jsonValue as bool';
      case SchemaType.object:
        return '$name.fromJson($jsonValue as Map<String, dynamic>)';
      case SchemaType.array:
        final itemsSchema = items!;
        final itemTypeName = itemsSchema.typeName();
        if (itemsSchema.type == SchemaType.object) {
          return '($jsonValue as List<dynamic>).map<$itemTypeName>((e) => '
              '$itemTypeName.fromJson(e as Map<String, dynamic>)).toList()';
        } else {
          return '($jsonValue as List<dynamic>).cast<$itemTypeName>()';
        }
    }
  }

  Map<String, dynamic> objectToTemplateContext() {
    final renderProperties = properties.entries.map((entry) {
      final name = entry.key;
      final schema = entry.value;
      return {
        'propertyName': name,
        'propertyType': schema.typeName(),
        'propertyToJson': schema.toJsonExpression(name),
        'propertyFromJson': schema.fromJsonExpression("json['$name']"),
      };
    });
    return {
      'schemaName': name,
      'hasProperties': renderProperties.isNotEmpty,
      'properties': renderProperties,
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
      'schemaName': name,
      'enumValues': enumValues.map(enumValueToTemplateContext).toList(),
    };
  }

  Map<String, dynamic> toTemplateContext() {
    if (isEnum) {
      return _enumToTemplateContext();
    } else {
      return objectToTemplateContext();
    }
  }

  String packageImport(Context context) {
    final snakeName = snakeFromCamel(name);
    return 'package:${context.packageName}/model/$snakeName.dart';
  }
}

extension ParameterGeneration on ResolvedParameter {
  Map<String, dynamic> toTemplateContext() {
    return {
      'paramName': name,
      'paramType': type.typeName(),
      'paramToJson': type.toJsonExpression(name),
      'paramFromJson': type.fromJsonExpression("json['$name']"),
    };
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
  });

  final Uri specUrl;
  final ResolvedSpec spec;
  final Directory outDir;
  final String packageName;
  final FileSystem fs;

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
    // final rendered = <ResolvedSchema>{};
    // final renderQueue = <ResolvedSchema>{};
    for (final api in spec.apis) {
      final renderContext = RenderContext();
      renderApi(renderContext, this, api);
      // Api files only contain the API class, any inline schemas
      // end up in the model files.
      for (final schema in renderContext.inlineSchemas) {
        renderRootSchema(this, schema);
      }
    }

    // // Render all the schemas that were collected while rendering the API.
    // while (renderQueue.isNotEmpty) {
    //   final schema = renderQueue.first;
    //   renderQueue.remove(schema);
    //   if (rendered.contains(schema)) {
    //     continue;
    //   }
    //   rendered.add(schema);
    //   // Only render objects and enums for now.
    //   // Otherwise we render an empty file for ship_condition.dart
    //   // which is an int type with min/max values.
    //   // if (schema.type != SchemaType.object && !schema.isEnum) {
    //   //   continue;
    //   // }
    //   final renderContext = renderRootSchema(this, schema);
    //   // renderQueue.addAll(renderContext.imported);
    // }
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
  // TODO(eseidel): This is the wrong way to determine where to render a
  // schema.
  /// Schemas to render in this file.
  List<ResolvedSchema> inlineSchemas = [];

  void visitSchema(ResolvedSchema schema) {
    collectSchema(schema);
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
        visitSchema(endpoint.requestBody!);
      }
    }
  }

  void collectSchema(ResolvedSchema schema) {
    if (schema.needsRender) {
      inlineSchemas.add(schema);
    }
    for (final entry in schema.properties.entries) {
      visitSchema(entry.value);
    }
    if (schema.type == SchemaType.array) {
      visitSchema(schema.items!);
    }
  }

  List<String> sortedPackageImports(
    Context context, {
    bool includeInlineSchema = false,
  }) {
    final imports = <String>{};
    if (includeInlineSchema) {
      for (final schema in inlineSchemas) {
        imports.add(schema.packageImport(context));
      }
    }
    return imports.toList()..sort();
  }

  List<Map<String, dynamic>> objectContexts() {
    return inlineSchemas
        .where((schema) => schema.type == SchemaType.object)
        .map((schema) => schema.toTemplateContext())
        .toList();
  }

  List<Map<String, dynamic>> enumContexts() {
    return inlineSchemas
        .where((schema) => schema.isEnum)
        .map((schema) => schema.toTemplateContext())
        .toList();
  }
}

/// Starts a new RenderContext for rendering a new schema file.
RenderContext renderRootSchema(Context context, ResolvedSchema schema) {
  // logger.info('Rendering ${schema.name}');

  final renderContext = RenderContext()..collectSchema(schema);
  // logger
  //   ..info('To import: ${renderContext.imported}')
  //   ..info('To render: ${renderContext.inlineSchemas}');

  final imports = renderContext.sortedPackageImports(context);
  final objects = renderContext.objectContexts();
  final enums = renderContext.enumContexts();

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
