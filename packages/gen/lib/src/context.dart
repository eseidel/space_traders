import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as p;
import 'package:space_gen/space_gen.dart';
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/parser.dart';
import 'package:space_gen/src/spec.dart';
import 'package:space_gen/src/string.dart';
import 'package:space_gen/src/visitor.dart';

Never _unimplemented(String message, String pointer) {
  throw UnimplementedError('$message at $pointer');
}

class Paths {
  static String apiFilePath(Api api) {
    // openapi generator does not use /src/ in the path.
    return 'lib/api/${api.fileName}.dart';
  }

  static String apiPackagePath(Api api) {
    return 'api/${api.fileName}.dart';
  }

  static String modelFilePath(Schema schema) {
    // openapi generator does not use /src/ in the path.
    return 'lib/model/${schema.fileName}.dart';
  }

  static String modelPackagePath(Schema schema) {
    return 'model/${schema.fileName}.dart';
  }
}

/// A convenience class created for each operation within a path item
/// for compatibility with our existing rendering code.
class Endpoint {
  const Endpoint({
    required this.method,
    required this.pathItem,
    required this.operation,
  });

  final Method method;
  final PathItem pathItem;
  final Operation operation;

  String get path => pathItem.path;

  String get tag => pathItem.tags.firstOrNull ?? 'Default';

  String get snakeName => operation.snakeName;

  List<RefOr<Parameter>> get parameters => operation.parameters;
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

extension OpenApiGeneration on OpenApi {
  /// The endpoints of the spec.
  List<Endpoint> get endpoints => paths.paths.values
      .expand(
        (p) => p.operations.entries.map(
          (e) => Endpoint(method: e.key, pathItem: p, operation: e.value),
        ),
      )
      .toList();

  /// Set of all endpoint tags in the spec.
  Set<String> get tags => endpoints.map((e) => e.tag).toSet();

  List<Api> get apis => tags
      .sorted()
      .map(
        (tag) => Api(
          name: tag,
          endpoints: endpoints.where((e) => e.tag == tag).toList(),
        ),
      )
      .toList();
}

extension _EndpointGeneration on Endpoint {
  String get methodName => lowercaseCamelFromSnake(snakeName);

  Uri uri(_Context context) => Uri.parse('${context.spec.serverUrl}$path');

  /// The type of the response.
  /// If there are multiple responses, we return the first one with a content
  /// type.
  SchemaRef? responseType(_Context context) {
    final responses = operation.responses;
    final maybeResponseRef =
        responses.successfulResponsesWithContent.firstOrNull;
    if (maybeResponseRef == null) {
      return null;
    }
    final content = context._resolve(maybeResponseRef).content;
    if (content == null) {
      return null;
    }
    return _contentSchemaRef(content, path);
  }

  Map<String, dynamic> toTemplateContext(_Context context) {
    final serverParameters = parameters.map((param) {
      return context._resolve<Parameter>(param).toTemplateContext(context);
    }).toList();

    final bodyObject = context._maybeResolve<RequestBody>(
      operation.requestBody,
    );
    final requestBody = bodyObject?.toTemplateContext(context);
    // Parameters as passed to the Dart function call, including the request
    // body if it exists.
    final dartParameters = [...serverParameters, ?requestBody];

    final responseSchema = context._maybeResolve(responseType(context));
    final returnType = responseSchema?.typeName(context) ?? 'void';
    final responseFromJson = responseSchema?.fromJsonExpression(
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
      'url': uri(context),
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

enum SchemaRenderType { enumeration, object, stringNewtype, numberNewtype, pod }

extension _SchemaBaseGeneration on SchemaBase {
  bool get createsNewType {
    if (this is Schema) {
      return (this as Schema).createsNewType;
    }
    // All other schema types create a new type.
    return true;
  }

  String typeName(_Context context) {
    if (this is Schema) {
      return (this as Schema).typeName(context);
    }
    // TODO(eseidel): Support other schema types.
    return 'dynamic';
  }

  String nullableTypeName(_Context context) {
    final typeName = this.typeName(context);
    return typeName.endsWith('?') ? typeName : '$typeName?';
  }

  String equalsExpression(String name, _Context context) {
    if (this is Schema) {
      return (this as Schema).equalsExpression(name, context);
    }
    // TODO(eseidel): Support other schema types.
    _unimplemented('equalsExpression', pointer);
  }

  String toJsonExpression(
    String dartName,
    _Context context, {
    required bool dartIsNullable,
  }) {
    if (this is Schema) {
      return (this as Schema).toJsonExpression(
        dartName,
        context,
        dartIsNullable: dartIsNullable,
      );
    }
    // TODO(eseidel): Support other schema types.
    _unimplemented('toJsonExpression', pointer);
  }

  String fromJsonExpression(
    String jsonValue,
    _Context context, {
    required bool jsonIsNullable,
    required bool dartIsNullable,
  }) {
    if (this is Schema) {
      return (this as Schema).fromJsonExpression(
        jsonValue,
        context,
        jsonIsNullable: jsonIsNullable,
        dartIsNullable: dartIsNullable,
      );
    }
    // TODO(eseidel): Support other schema types.
    _unimplemented('fromJsonExpression', pointer);
  }

  String? defaultValueString(_Context context) {
    if (this is Schema) {
      return (this as Schema).defaultValueString(context);
    }
    // TODO(eseidel): Support other schema types.
    _unimplemented('defaultValueString', pointer);
  }

  bool hasDefaultValue(_Context context) {
    if (this is Schema) {
      return (this as Schema).hasDefaultValue(context);
    }
    // TODO(eseidel): Support other schema types.
    _unimplemented('hasDefaultValue', pointer);
  }

  dynamic get defaultValue {
    if (this is Schema) {
      return (this as Schema).defaultValue;
    }
    // TODO(eseidel): Support other schema types.
    _unimplemented('defaultValue', pointer);
  }

  /// package import string for this schema.
  String packageImport(_Context context) {
    return 'package:${context.packageName}/model/$snakeName.dart';
  }
}

extension _SchemaGeneration on Schema {
  /// Schema name in file name format.
  String get fileName => snakeName;

  /// Schema name in class name format. Only valid for enum, object and
  /// newtype schemas.
  String get className {
    if (!isEnum && type != SchemaType.object && !useNewType) {
      throw Exception('Schema is not an enum or object: $this');
    }
    return camelFromSnake(snakeName);
  }

  /// Whether this schema creates a new type and thus needs to be rendered.
  bool get createsNewType => type == SchemaType.object || isEnum || useNewType;

  /// The name of an enum value.
  String enumValueName(_Context context, String jsonName) {
    if (context.quirks.screamingCapsEnums) {
      return jsonName;
    }
    // Dart style uses camelCase.
    return camelFromScreamingCaps(jsonName);
  }

  /// The type of schema to render.
  SchemaRenderType get renderType {
    if (isEnum) {
      return SchemaRenderType.enumeration;
    }
    if (type == SchemaType.string && useNewType) {
      return SchemaRenderType.stringNewtype;
    }
    if (type == SchemaType.number && useNewType) {
      return SchemaRenderType.numberNewtype;
    }
    if (type == SchemaType.object) {
      return SchemaRenderType.object;
    }
    return SchemaRenderType.pod;
  }

  /// Whether this schema is a date time.
  bool get isDateTime => type == SchemaType.string && format == 'date-time';

  /// Whether this schema is an enum.
  bool get isEnum => type == SchemaType.string && enumValues.isNotEmpty;

  // Is a Map with a specified value type.
  SchemaBase? valueSchema(_Context context) {
    if (type != SchemaType.object) {
      return null;
    }
    return context._maybeResolve(additionalProperties);
  }

  /// The type name of this schema.
  String typeName(_Context context) {
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
        final itemsSchema = context._maybeResolve(items);
        if (itemsSchema == null) {
          throw StateError('Items schema is null: $this');
        }
        return 'List<${itemsSchema.typeName(context)}>';
      case SchemaType.unknown:
        return 'dynamic';
    }
    // throw UnimplementedError('Unknown type $type');
  }

  String nullableTypeName(_Context context) {
    final typeName = this.typeName(context);
    return typeName.endsWith('?') ? typeName : '$typeName?';
  }

  String equalsExpression(String name, _Context context) {
    switch (type) {
      case SchemaType.object:
        return '$name == other.$name';
      case SchemaType.array:
        return 'listsEqual($name, other.$name)';
      case SchemaType.string:
      case SchemaType.integer:
      case SchemaType.number:
      case SchemaType.boolean:
        return '$name == other.$name';
      case SchemaType.unknown:
        return 'identical($name, other.$name)';
    }
  }

  /// The toJson expression for this schema.
  String toJsonExpression(
    String dartName,
    _Context context, {
    required bool dartIsNullable,
  }) {
    final nameCall = dartIsNullable ? '$dartName?' : dartName;
    switch (type) {
      case SchemaType.string:
        if (isDateTime) {
          return '$nameCall.toIso8601String()';
        } else if (isEnum) {
          return '$nameCall.toJson()';
        }
        return dartName;
      case SchemaType.integer:
      case SchemaType.number:
      case SchemaType.boolean:
        return dartName;
      case SchemaType.object:
        return '$nameCall.toJson()';
      case SchemaType.array:
        final itemsSchema = context._maybeResolve(items);
        if (itemsSchema == null) {
          throw StateError('Items schema is null: $this');
        }
        switch (itemsSchema.type) {
          case SchemaType.unknown:
          case SchemaType.string:
          case SchemaType.integer:
          case SchemaType.number:
          case SchemaType.boolean:
            // Don't call toJson on primitives.
            return dartName;
          case SchemaType.object:
          case SchemaType.array:
            return '$nameCall.map((e) => e.toJson()).toList()';
        }
      case SchemaType.unknown:
        return dartName;
    }
  }

  String jsonStorageType({required bool isNullable}) {
    switch (type) {
      case SchemaType.string:
        return isNullable ? 'String?' : 'String';
      case SchemaType.integer:
        return isNullable ? 'int?' : 'int';
      case SchemaType.number:
        // Dart's json parser parses '1' as an int, and int is a separate
        // type from double, however both are subtypes of num, so we can cast
        // to num and then convert to double.
        return isNullable ? 'num?' : 'num';
      case SchemaType.boolean:
        return isNullable ? 'bool?' : 'bool';
      case SchemaType.object:
        return isNullable ? 'Map<String, dynamic>?' : 'Map<String, dynamic>';
      case SchemaType.array:
        return isNullable ? 'List<dynamic>?' : 'List<dynamic>';
      case SchemaType.unknown:
        return 'dynamic';
    }
  }

  String _orDefault({
    required _Context context,
    required bool jsonIsNullable,
    required bool dartIsNullable,
  }) {
    if (jsonIsNullable && !dartIsNullable) {
      final defaultValue = defaultValueString(context);
      if (defaultValue == null) {
        throw StateError('No default value for nullable property: $this');
      }
      return '?? $defaultValue';
    }
    return '';
  }

  /// The fromJson expression for this schema.
  String fromJsonExpression(
    String jsonValue,
    _Context context, {
    required bool jsonIsNullable,
    required bool dartIsNullable,
  }) {
    final jsonType = jsonStorageType(isNullable: jsonIsNullable);
    final orDefault = _orDefault(
      context: context,
      jsonIsNullable: jsonIsNullable,
      dartIsNullable: dartIsNullable,
    );

    switch (type) {
      case SchemaType.string:
        if (isDateTime) {
          if (jsonIsNullable) {
            return 'maybeParseDateTime($jsonValue as $jsonType) $orDefault';
          } else {
            return 'DateTime.parse($jsonValue as $jsonType)';
          }
        } else if (isEnum) {
          final jsonMethod = jsonIsNullable ? 'maybeFromJson' : 'fromJson';
          return '$className.$jsonMethod($jsonValue as $jsonType) $orDefault';
        }
        return '$jsonValue as $jsonType';
      case SchemaType.integer:
      case SchemaType.boolean:
        return '($jsonValue as $jsonType) $orDefault';
      case SchemaType.number:
        final nullAware = jsonIsNullable ? '?' : '';
        return '(($jsonValue as $jsonType)$nullAware.toDouble()) $orDefault';
      case SchemaType.object:
        final jsonMethod = jsonIsNullable ? 'maybeFromJson' : 'fromJson';
        return '$className.$jsonMethod($jsonValue as $jsonType) $orDefault';
      case SchemaType.array:
        final itemsSchema = context._maybeResolve(items);
        if (itemsSchema == null) {
          throw StateError('Items schema is null: $this');
        }
        final itemTypeName = itemsSchema.typeName(context);

        // List has special handling for nullability since we want to cast
        // through List<dynamic> first before casting to the item type.
        final castAsList = jsonIsNullable
            ? '($jsonValue as List?)?'
            : '($jsonValue as List)';
        final itemsFromJson = itemsSchema.fromJsonExpression(
          'e',
          context,
          dartIsNullable: false,
          // Unless itemSchema itself has a nullable type this is always false.
          jsonIsNullable: false,
        );
        // If it doesn't create a new type we can just cast the list.
        if (!itemsSchema.createsNewType) {
          return '$castAsList.cast<$itemTypeName>() $orDefault';
        }
        return '$castAsList.map<$itemTypeName>('
            '(e) => $itemsFromJson).toList() $orDefault';
      case SchemaType.unknown:
        return '$jsonValue $orDefault';
    }
  }

  // OpenAPI defaults arrays to empty, so we match for now.
  bool shouldApplyListDefaultToEmptyQuirk(_Context context) =>
      type == SchemaType.array && context.quirks.allListsDefaultToEmpty;

  /// The default value of this schema as a string.
  String? defaultValueString(_Context context) {
    // If the type of this schema is an object we need to convert the default
    // value to that object type.
    if (isEnum && defaultValue is String) {
      return '$className.${enumValueName(context, defaultValue as String)}';
    }
    if (shouldApplyListDefaultToEmptyQuirk(context)) {
      return 'const []';
    }
    return defaultValue?.toString();
  }

  bool hasDefaultValue(_Context context) =>
      defaultValue != null || shouldApplyListDefaultToEmptyQuirk(context);

  // isNullable means it's optional for the server, use nullable storage.
  bool propertyDartIsNullable({
    required String jsonName,
    required _Context context,
    required bool propertyHasDefaultValue,
  }) {
    final inRequiredList = required.contains(jsonName);
    if (context.quirks.nonNullableDefaultValues) {
      return !inRequiredList && !propertyHasDefaultValue;
    }
    return !inRequiredList;
  }

  /// `this` is the schema of the object containing the property.
  /// [property] is the schema of the property itself.
  Map<String, dynamic> propertyTemplateContext({
    required String jsonName,
    required SchemaBase property,
    required _Context context,
  }) {
    // Properties only need to avoid reserved words for openapi compat.
    // TODO(eseidel): Remove this once we've migrated to the new generator.
    final dartName = avoidReservedWord(jsonName);
    final hasDefaultValue = property.hasDefaultValue(context);
    final jsonIsNullable = !required.contains(jsonName);
    final dartIsNullable = propertyDartIsNullable(
      jsonName: jsonName,
      context: context,
      propertyHasDefaultValue: hasDefaultValue,
    );

    // Means that the constructor parameter is required which is only true if
    // both the json property is required and it does not have a default.
    final useRequired = required.contains(jsonName) && !hasDefaultValue;
    return {
      'dartName': dartName,
      'jsonName': jsonName,
      'useRequired': useRequired,
      'dartIsNullable': dartIsNullable,
      'hasDefaultValue': hasDefaultValue,
      'defaultValue': property.defaultValueString(context),
      'type': property.typeName(context),
      'nullableType': property.nullableTypeName(context),
      'equals': property.equalsExpression(dartName, context),
      'toJson': property.toJsonExpression(
        dartName,
        context,
        dartIsNullable: dartIsNullable,
      ),
      'fromJson': property.fromJsonExpression(
        "json['$jsonName']",
        context,
        dartIsNullable: dartIsNullable,
        jsonIsNullable: jsonIsNullable,
      ),
    };
  }

  /// Template context for an object schema.
  Map<String, dynamic> objectTemplateContext(_Context context) {
    if (type != SchemaType.object) {
      throw StateError('Schema is not an object: $this');
    }
    final renderProperties = properties.entries.map((entry) {
      final jsonName = entry.key;
      final schema = context._maybeResolve(entry.value);
      if (schema == null) {
        throw StateError('Properties schema is null: $this');
      }
      return propertyTemplateContext(
        jsonName: jsonName,
        property: schema,
        context: context,
      );
    }).toList();

    final valueSchema = this.valueSchema(context);
    final hasAdditionalProperties = valueSchema != null;
    // Force named properties to be rendered if hasAdditionalProperties is true.
    final hasProperties =
        renderProperties.isNotEmpty || hasAdditionalProperties;
    const isNullable = false;
    final propertiesCount =
        renderProperties.length + (hasAdditionalProperties ? 1 : 0);
    if (propertiesCount == 0) {
      throw StateError('Object schema has no properties: $this');
    }
    return {
      'typeName': className,
      'nullableTypeName': nullableTypeName(context),
      'hasProperties': hasProperties,
      // Special case behavior hashCode with only one property.
      'hasOneProperty': propertiesCount == 1,
      'properties': renderProperties,
      'hasAdditionalProperties': hasAdditionalProperties,
      'additionalPropertiesName': 'entries', // Matching OpenAPI.
      'valueSchema': valueSchema?.typeName(context),
      'valueToJson': valueSchema?.toJsonExpression(
        'value',
        context,
        dartIsNullable: isNullable,
      ),
      'valueFromJson': valueSchema?.fromJsonExpression(
        'value',
        context,
        jsonIsNullable: isNullable,
        dartIsNullable: isNullable,
      ),
      'fromJsonJsonType': context.fromJsonJsonType,
      'castFromJsonArg': context.quirks.dynamicJson,
      'mutableModels': context.quirks.mutableModels,
    };
  }

  Map<String, dynamic> stringNewtypeTemplateContext() {
    if (type != SchemaType.string) {
      throw StateError('Schema is not a string: $this');
    }
    if (!useNewType) {
      throw StateError('Schema is not a newtype: $this');
    }
    return {'typeName': className};
  }

  Map<String, dynamic> numberNewtypeTemplateContext() {
    if (type != SchemaType.number) {
      throw StateError('Schema is not a number: $this');
    }
    if (!useNewType) {
      throw StateError('Schema is not a newtype: $this');
    }
    return {'typeName': className};
  }

  String _sharedPrefix(List<String> values) {
    final prefix = '${values.first.split('_').first}_';
    for (final value in values) {
      if (!value.startsWith(prefix)) {
        return '';
      }
    }
    return prefix;
  }

  String avoidReservedWord(String value) {
    if (isReservedWord(value)) {
      return '${value}_';
    }
    return value;
  }

  /// Template context for an enum schema.
  Map<String, dynamic> enumTemplateContext(_Context context) {
    if (!isEnum) {
      throw StateError('Schema is not an enum: $this');
    }
    final sharedPrefix = _sharedPrefix(enumValues);
    Map<String, dynamic> enumValueToTemplateContext(String value) {
      var dartName = enumValueName(context, value);
      // OpenAPI also removes shared prefixes from enum values.
      dartName = dartName.replaceAll(sharedPrefix, '');
      // And avoids reserved words.
      dartName = avoidReservedWord(dartName);
      return {'enumValueName': dartName, 'enumValue': value};
    }

    return {
      'typeName': className,
      'nullableTypeName': nullableTypeName(context),
      'enumValues': enumValues.map(enumValueToTemplateContext).toList(),
    };
  }
}

/// Extensions for rendering parameters.
extension _ParameterGeneration on Parameter {
  /// Template context for a parameter.
  Map<String, dynamic> toTemplateContext(_Context context) {
    final typeSchema = context._maybeResolve(type);
    if (typeSchema == null) {
      throw StateError('Type schema is null: $this');
    }
    final isNullable = !isRequired;
    final specName = name;
    final dartName = lowercaseCamelFromSnake(name);
    final jsonName = name;
    return {
      'name': name,
      'dartName': dartName,
      'bracketedName': '{$specName}',
      'required': isRequired,
      'hasDefaultValue': typeSchema.defaultValue != null,
      'defaultValue': typeSchema.defaultValueString(context),
      'isNullable': isNullable,
      'type': typeSchema.typeName(context),
      'nullableType': typeSchema.nullableTypeName(context),
      'sendIn': sendIn.name,
      'toJson': typeSchema.toJsonExpression(
        dartName,
        context,
        dartIsNullable: isNullable,
      ),
      'fromJson': typeSchema.fromJsonExpression(
        "json['$jsonName']",
        context,
        jsonIsNullable: isNullable,
        dartIsNullable: isNullable,
      ),
    };
  }
}

SchemaRef? _contentSchemaRef(Map<String, MediaType> content, String pointer) {
  final schemaRef = content['application/json']?.schema;
  if (schemaRef != null) {
    return schemaRef;
  }
  // If there is no application/json media type, use the first one.
  // This is a hack to make petstore work enough for now.
  final firstKey = content.keys.first;
  logger
    ..warn('No application/json media type found for $pointer')
    ..detail('Using first media type: $firstKey');
  return content[firstKey]?.schema;
}

extension _RequestBodyGeneration on RequestBody {
  Map<String, dynamic> toTemplateContext(_Context context) {
    final schemaRef = _contentSchemaRef(content, pointer);
    if (schemaRef == null) {
      throw StateError('Schema is null: $this');
    }
    final schema = context._resolve(schemaRef);
    final typeName = schema.typeName(context);
    // TODO(eseidel): Why don't we have a name for request bodies?
    final paramName = (typeName[0].toLowerCase() + typeName.substring(1))
        .split('<')
        .first;
    // TODO(eseidel): Share code with Parameter.toTemplateContext.
    final isNullable = !isRequired;
    return {
      'name': paramName,
      'dartName': paramName,
      'bracketedName': '{$paramName}',
      'required': isRequired,
      'hasDefaultValue': schema.defaultValue != null,
      'defaultValue': schema.defaultValueString(context),
      'type': typeName,
      'nullableType': schema.nullableTypeName(context),
      'toJson': schema.toJsonExpression(
        paramName,
        context,
        dartIsNullable: isNullable,
      ),
      'fromJson': schema.fromJsonExpression(
        'json',
        context,
        jsonIsNullable: isNullable,
        dartIsNullable: isNullable,
      ),
    };
  }
}

/// Extensions for rendering schema references.
extension _SchemaRefGeneration on RefOr<dynamic> {
  /// package import string for this schema reference.
  String packageImport(_Context context) {
    final name = p.basenameWithoutExtension(ref!);
    final snakeName = snakeFromCamel(name);
    return 'package:${context.packageName}/model/$snakeName.dart';
  }
}

typedef RunProcess =
    ProcessResult Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
    });

/// Context for rendering the spec.
/// This is separate from a RenderContext which is per-file.
class _Context {
  /// Create a new context for rendering the spec.
  _Context({
    required this.specUrl,
    required this.spec,
    required this.outDir,
    required this.packageName,
    required this.refRegistry,
    Directory? templateDir,
    RunProcess? runProcess,
    this.quirks = const Quirks(),
  }) : fs = outDir.fileSystem,
       templateDir =
           templateDir ?? outDir.fileSystem.directory('lib/templates'),
       runProcess = runProcess ?? Process.runSync {
    final dir = this.templateDir;
    if (!dir.existsSync()) {
      throw Exception('Template directory does not exist: ${dir.path}');
    }
  }

  /// The url of the spec being rendered.  Used for resolving relative urls.
  final Uri specUrl;

  /// The spec being rendered.
  final OpenApi spec;

  /// The output directory.
  final Directory outDir;

  /// The package name this spec is being rendered into.
  final String packageName;

  /// The directory containing the templates.
  final Directory templateDir;

  /// The file system where the rendered files will go.
  final FileSystem fs;

  /// The registry of all the objects we've parsed so far.
  /// This must be fully populated before rendering.
  final RefRegistry refRegistry;

  /// The function to run a process. Allows for mocking in tests.
  final RunProcess runProcess;

  /// The quirks to use for rendering.
  final Quirks quirks;

  /// Load a template from the template directory.
  Template _loadTemplate(String name) {
    return Template(
      templateDir.childFile('$name.mustache').readAsStringSync(),
      partialResolver: _loadTemplate,
      name: name,
    );
  }

  /// The type of the json object passed to fromJson.
  String get fromJsonJsonType =>
      quirks.dynamicJson ? 'dynamic' : 'Map<String, dynamic>';

  /// Resolve a nullable [SchemaRef] into a nullable [Schema].
  T? _maybeResolve<T>(RefOr<T>? ref) {
    if (ref == null) {
      return null;
    }
    return _resolve(ref);
  }

  /// Resolve a [SchemaRef] into a [Schema].
  T _resolve<T>(RefOr<T> ref) {
    if (ref.object != null) {
      return ref.object!;
    }
    final uri = specUrl.resolve(ref.ref!);
    return _resolveUri(uri);
  }

  /// Resolve a uri into a [Schema].
  T _resolveUri<T>(Uri uri) => refRegistry.get<T>(uri);

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
    final output = _loadTemplate(template).renderString(context);
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

  /// Render the API classes and supporting models.
  Set<Uri> _renderApis() {
    final rendered = <Uri>{};
    final renderQueue = <Uri>{};
    Set<Uri> urisFromRefs(Set<RefOr<dynamic>> refs) {
      return refs.map((ref) => specUrl.resolve(ref.ref!)).toSet();
    }

    Set<Uri> urisFromSchemas(Iterable<SchemaBase> schemas) {
      return schemas
          .map((schema) => specUrl.replace(fragment: schema.pointer))
          .toSet();
    }

    for (final api in spec.apis) {
      final schemas = _renderApi(specUrl, this, api);
      // Api files only contain the API class, any inline schemas
      // end up in the model files.
      renderQueue.addAll([
        ...urisFromSchemas(schemas.schemas),
        ...urisFromRefs(schemas.refs),
      ]);
    }

    // Render all the schemas that were collected while rendering the API.
    while (renderQueue.isNotEmpty) {
      final uri = renderQueue.first;
      renderQueue.remove(uri);
      if (rendered.contains(uri)) {
        continue;
      }
      final schema = _resolveUri<dynamic>(uri);
      if (schema is Schema) {
        final renderContext = _renderSchema(this, schema);
        renderQueue.addAll([
          ...urisFromSchemas(renderContext.schemas),
          ...urisFromRefs(renderContext.refs),
        ]);
        rendered.add(uri);
      }
    }
    return rendered;
  }

  /// Render the api client.
  void _renderApiClient() {
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
  void _renderPublicApi(Iterable<Schema> renderedModels) {
    final paths = [
      ...spec.apis.map(Paths.apiPackagePath),
      ...renderedModels.map(Paths.modelPackagePath),
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
  void render() {
    // Set up the package directory.
    _renderDirectory();
    // Renders all APIs and models.  Returns urls of all rendered schemas.
    final rendered = _renderApis();
    _renderApiClient();
    // Render the combined api.dart exporting all rendered schemas.
    final renderedModels = rendered.map(refRegistry.get<Schema>);
    _renderPublicApi(renderedModels);
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
  required OpenApi spec,
  required RefRegistry refRegistry,
  Directory? templateDir,
  RunProcess? runProcess,
  Quirks quirks = const Quirks(),
}) {
  _Context(
    specUrl: specUri,
    spec: spec,
    outDir: outDir,
    packageName: packageName,
    refRegistry: refRegistry,
    templateDir: templateDir,
    runProcess: runProcess,
    quirks: quirks,
  ).render();
}

class _RenderedSchemaVisitor extends Visitor {
  final Set<RefOr<dynamic>> refs = {};
  final Set<SchemaBase> schemas = {};

  @override
  void visitReference<T>(RefOr<T> ref) {
    // Only collect RefOr when ref is not null (object is null).
    if (ref.ref != null) {
      refs.add(ref);
    }
  }

  @override
  void visitSchema(SchemaBase schema) {
    if (schema.createsNewType) {
      schemas.add(schema);
    }
  }
}

class _SchemaSet {
  _SchemaSet(this.refs, this.schemas);

  final Set<RefOr<dynamic>> refs;
  final Set<SchemaBase> schemas;

  /// Get the sorted package imports for this render context.
  List<String> sortedPackageImports(_Context context) {
    final imports = <String>{};
    for (final ref in refs) {
      imports.add(ref.packageImport(context));
    }
    for (final schema in schemas) {
      imports.add(schema.packageImport(context));
    }
    return imports.toList()..sort();
  }
}

_SchemaSet _importsForSchema(Schema schema) {
  final collector = _RenderedSchemaVisitor();
  SpecWalker(collector).walkSchema(schema);
  return _SchemaSet(collector.refs, collector.schemas);
}

_SchemaSet _importsForApi(Api api) {
  final collector = _RenderedSchemaVisitor();
  // An Endpoint is a rendering-only concept.  The SpecWalker works on spec
  // classes, so walk to PathItems within the endpoints.
  for (final endpoint in api.endpoints) {
    SpecWalker(collector).walkPathItem(endpoint.pathItem);
  }
  return _SchemaSet(collector.refs, collector.schemas);
}

/// Starts a new RenderContext for rendering a new schema file.
_SchemaSet _renderSchema(_Context context, Schema schema) {
  final schemas = _importsForSchema(schema);

  final imports = schemas.sortedPackageImports(context);
  final Map<String, dynamic> schemaContext;
  final String template;
  switch (schema.renderType) {
    case SchemaRenderType.enumeration:
      schemaContext = schema.enumTemplateContext(context);
      template = 'schema_enum';
    case SchemaRenderType.object:
      schemaContext = schema.objectTemplateContext(context);
      template = 'schema_object';
    case SchemaRenderType.stringNewtype:
      schemaContext = schema.stringNewtypeTemplateContext();
      template = 'schema_string_newtype';
    case SchemaRenderType.numberNewtype:
      schemaContext = schema.numberNewtypeTemplateContext();
      template = 'schema_number_newtype';
    case SchemaRenderType.pod:
      throw StateError('Pod schemas should not be rendered: $schema');
  }

  imports.add('package:${context.packageName}/model_helpers.dart');

  final outPath = Paths.modelFilePath(schema);
  logger.detail('rendering $outPath from ${schema.pointer}');
  context._renderTemplate(
    template: template,
    outPath: outPath,
    context: {'imports': imports, ...schemaContext},
  );
  return schemas;
}

_SchemaSet _renderApi(Uri schemaUrl, _Context context, Api api) {
  final apiSchemas = _importsForApi(api);
  final endpoints = api.endpoints
      .map((e) => e.toTemplateContext(context))
      .toList();

  final imports = {
    ...apiSchemas.sortedPackageImports(context),
    'dart:io', // For HttpStatus
    'package:${context.packageName}/api_exception.dart',
  };

  // The OpenAPI generator only includes the APIs in the api/ directory
  // all other classes and enums go in the model/ directory even ones
  // which were defined inline in the main spec.
  context._renderTemplate(
    template: 'api',
    outPath: Paths.apiFilePath(api),
    context: {
      'className': api.className,
      'imports': imports,
      'endpoints': endpoints,
      'packageName': context.packageName,
    },
  );
  return apiSchemas;
}
