import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/spec.dart';
import 'package:space_gen/src/string.dart';

T _required<T>(MapContext json, String key) {
  final value = json[key];
  if (value == null) {
    throw FormatException(
      'Required key not found: $key in ${json.pointer}: $json',
    );
  }
  return value as T;
}

MapContext _requiredMap(MapContext json, String key) {
  final value = json[key];
  // Check the value is not null to avoid the childAsMap throwing StateError.
  if (value == null) {
    throw FormatException(
      'Required key not found: $key in ${json.pointer}: $json',
    );
  }
  return json.childAsMap(key);
}

ListContext _requiredList(MapContext json, String key) {
  final value = json[key];
  if (value == null) {
    throw FormatException(
      'Required key not found: $key in ${json.pointer}: $json',
    );
  }
  return json.childAsList(key);
}

void _expect(bool condition, ParseContext json, String message) {
  if (!condition) {
    throw FormatException('$message in ${json.pointer}');
  }
}

T? _optional<T>(MapContext parent, String key) {
  final value = parent[key];
  if (value is T?) {
    return value;
  }
  throw FormatException(
    'Key $key is not of type $T: $value (in ${parent.pointer})',
  );
}

MapContext? _optionalMap(MapContext parent, String key) {
  final value = parent[key];
  if (value == null) {
    return null;
  }
  if (value is! Map<String, dynamic>) {
    throw FormatException(
      'Key $key is not of type Map<String, dynamic>: $value (in ${parent.pointer})',
    );
  }
  return parent.childAsMap(key);
}

ListContext? _optionalList(MapContext parent, String key) {
  final value = parent[key];
  if (value == null) {
    return null;
  }
  if (value is! List<dynamic>) {
    throw FormatException(
      'Key $key is not of type List<dynamic>: $value (in ${parent.pointer})',
    );
  }
  return parent.childAsList(key);
}

// void _unimplemented(Json json, String key) {
//   final value = json[key];
//   if (value != null) {
//     throw UnimplementedError('Unsupported key: $key in $json');
//   }
// }

void _ignored(MapContext parent, String key) {
  final value = parent[key];
  if (value != null) {
    logger.detail('Ignoring key: $key in ${parent.pointer}');
  }
}

void _warn(MapContext context, String message) {
  logger.warn('$message in ${context.pointer}');
}

void _error(MapContext context, String message) {
  throw FormatException('$message in ${context.pointer}');
}

/// Parse a parameter from a json object.
Parameter parseParameter(MapContext json) {
  final schema = _optionalMap(json, 'schema');
  final hasSchema = schema != null;
  final hasContent = _optional<Json>(json, 'content') != null;

  // Common fields.
  final name = _required<String>(json, 'name');
  final description = _optional<String>(json, 'description');
  final required = _optional<bool>(json, 'required') ?? false;
  final sendIn = SendIn.fromJson(_required<String>(json, 'in'));
  _ignored(json, 'deprecated');
  _ignored(json, 'allowEmptyValue');

  final SchemaRef type;
  if (hasSchema) {
    if (hasContent) {
      _error(json, 'Parameter cannot have both schema and content');
    }
    // Schema fields.
    type = parseSchemaOrRef(schema);
    _ignored(json, 'style');
    _ignored(json, 'explode');
    _ignored(json, 'allowReserved');
    _ignored(json, 'example');
    _ignored(json, 'examples');
  } else {
    if (!hasSchema && !hasContent) {
      _error(json, 'Parameter must have either schema or content');
    }
    // Content fields.
    // Use an explicit throw so Dart can see `type` is always set.
    throw const FormatException('Content parameters not supported');
  }

  if (sendIn == SendIn.cookie) {
    throw UnimplementedError('Cookie parameters not supported');
  }
  if (sendIn == SendIn.path) {
    if (type.schema?.type != SchemaType.string) {
      throw UnimplementedError('Path parameters must be strings');
    }
    if (required != true) {
      throw UnimplementedError('Path parameters must be required');
    }
  }

  return Parameter(
    name: name,
    description: description,
    isRequired: required,
    sendIn: sendIn,
    type: type,
  );
}

/// Parse a schema from a json object.
Schema parseSchema(MapContext json) {
  final type = SchemaType.fromJson(json['type'] as String? ?? 'unknown');
  final propertiesJson = _optionalMap(json, 'properties');
  final properties = <String, SchemaRef>{};
  if (propertiesJson != null) {
    for (final name in propertiesJson.json.keys) {
      final snakeName = snakeFromCamel(name);
      final childContext = propertiesJson
          .childAsMap(name)
          .addSnakeName(snakeName);
      properties[name] = parseSchemaOrRef(childContext);
    }
  }
  final items = _optionalMap(json, 'items');
  SchemaRef? itemSchema;
  if (items != null) {
    const innerName = 'inner'; // Matching OpenAPI.
    itemSchema = parseSchemaOrRef(items.addSnakeName(innerName));
  }

  _ignored(json, 'nullable');
  _ignored(json, 'readOnly');
  _ignored(json, 'writeOnly');
  _ignored(json, 'discriminator');
  _ignored(json, 'xml');
  _ignored(json, 'example');
  _ignored(json, 'examples');
  _ignored(json, 'externalDocs');

  final defaultValue = _optional<dynamic>(json, 'default');

  final required = json['required'] as List<dynamic>? ?? [];
  final description = json['description'] as String? ?? '';
  final enumValues = json['enum'] as List<dynamic>? ?? [];
  if (enumValues.isNotEmpty) {
    if (type != SchemaType.string) {
      throw UnimplementedError(
        'Enum values are currently only supported for string types',
      );
    }
  }
  final format = json['format'] as String?;
  // This isn't quite correct, since it doesn't support boolean values.
  final additionalProperties = _optionalMap(json, 'additionalProperties');
  SchemaRef? additionalPropertiesSchema;
  if (additionalProperties != null) {
    additionalPropertiesSchema = parseSchemaOrRef(additionalProperties);
  }

  final schema = Schema(
    pointer: json.pointer.toString(),
    snakeName: json.snakeName,
    type: type,
    properties: properties,
    required: required.cast<String>(),
    description: description,
    items: itemSchema,
    enumValues: enumValues.cast<String>(),
    format: format,
    additionalProperties: additionalPropertiesSchema,
    defaultValue: defaultValue,
    useNewType: json.isTopLevelComponent,
  );
  json.addObject(schema);
  return schema;
}

/// Parse a schema or a reference to a schema.
/// https://spec.openapis.org/oas/v3.0.0#schemaObject
/// https://spec.openapis.org/oas/v3.0.0#relative-references-in-urls
SchemaRef parseSchemaOrRef(MapContext json) {
  if (json.containsKey(r'$ref')) {
    return SchemaRef.ref(json[r'$ref'] as String);
  }

  if (json.containsKey('oneOf')) {
    // TODO(eseidel): Support oneOf
    throw UnimplementedError('OneOf not supported');
  }

  if (json.containsKey('allOf')) {
    final allOf = json.childAsList('allOf');
    if (allOf.length != 1) {
      throw UnimplementedError('AllOf with ${allOf.length} items');
    }
    return parseSchemaOrRef(allOf.indexAsMap(0));
  }

  if (json.containsKey('anyOf')) {
    final anyOf = json.childAsList('anyOf');
    if (anyOf.length == 1) {
      return parseSchemaOrRef(anyOf.indexAsMap(0));
    }
    if (anyOf.length == 2) {
      final first = anyOf.indexAsMap(0);
      final second = anyOf.indexAsMap(1);

      // Two special case hacks to make space_traders work for now.
      // One is if one is a type and the other is type=null, we just
      // pretend the first is just marked nullable.
      if (first.containsKey('type') && second.containsKey('type')) {
        final firstType = first['type'] as String;
        final secondType = second['type'] as String;
        if (firstType == 'boolean' && secondType == 'null') {
          return parseSchemaOrRef(first);
        }
      }

      // The second hack is if one is an array of ref and the second is
      // that ref, we just pretend it's just an array of that ref.
      if (first.containsKey('items') && second.containsKey(r'$ref')) {
        final items = first['items'] as Json;
        final ref = second[r'$ref'] as String;
        if (items[r'$ref'] == ref) {
          return parseSchemaOrRef(first);
        }
      }
    }

    throw UnimplementedError('AnyOf with ${anyOf.length} items');
  }

  return SchemaRef.schema(parseSchema(json));
}

/// Parse a schema or a reference to a schema.
/// https://spec.openapis.org/oas/v3.0.0#schemaObject
/// https://spec.openapis.org/oas/v3.0.0#relative-references-in-urls
RefOr<RequestBody> parseRequestBodyOrRef(MapContext json) {
  if (json.containsKey(r'$ref')) {
    return RefOr<RequestBody>.ref(json[r'$ref'] as String);
  }
  final body = parseRequestBody(json);
  return RefOr<RequestBody>.object(body);
}

RequestBody parseRequestBody(MapContext json) {
  final content = _requiredMap(json, 'content');
  final applicationJson = _requiredMap(content, 'application/json');
  final schema = parseSchemaOrRef(applicationJson.childAsMap('schema'));
  _ignored(json, 'description');

  final isRequired = json['required'] as bool? ?? false;
  final body = RequestBody(
    pointer: json.pointer.toString(),
    isRequired: isRequired,
    schema: schema,
  );
  json.addObject(body);
  return body;
}

/// Parse an endpoint from a json object.
Endpoint parseEndpoint({
  required MapContext json,
  required String path,
  required Method method,
}) {
  final snakeName =
      (json['operationId'] as String? ?? Uri.parse(path).pathSegments.last)
          .replaceAll('-', '_');

  final context = json.addSnakeName(snakeName);
  final responsesJson = _optionalMap(json, 'responses');
  final responses = responsesJson == null
      ? <Response>[]
      : parseResponses(responsesJson);
  final tags = _optional<List<dynamic>>(json, 'tags');
  final tag = tags?.firstOrNull as String? ?? 'Default';
  final parametersJson = _optionalList(json, 'parameters');
  final parameters = parametersJson == null
      ? <Parameter>[]
      : parametersJson.indexed
            .map(
              (indexed) => parseParameter(
                context
                    .childAsList('parameters')
                    .indexAsMap(indexed.$1)
                    .addSnakeName('parameter${indexed.$1}'),
              ),
            )
            .toList();
  final requestBodyJson = _optionalMap(json, 'requestBody');
  RefOr<RequestBody>? requestBody;
  if (requestBodyJson != null) {
    requestBody = parseRequestBodyOrRef(requestBodyJson);
  }
  return Endpoint(
    path: path,
    method: method,
    tag: tag,
    responses: responses,
    snakeName: snakeName,
    parameters: parameters,
    requestBody: requestBody,
  );
}

List<Response> parseResponses(MapContext json) {
  final responseCodes = json.keys.toList()..remove('204');
  if (responseCodes.length != 1) {
    throw UnimplementedError(
      'Multiple responses not supported: ${json.pointer}',
    );
  }

  final responseCode = responseCodes.first;
  final responseTypes = json
      .childAsMap(responseCode)
      .addSnakeName(responseCode);
  final content = _optionalMap(responseTypes, 'content');
  if (content == null) {
    return [];
  }
  final jsonResponse = _requiredMap(content, 'application/json');
  final schema = jsonResponse.childAsMap('schema').addSnakeName('response');
  return [
    Response(code: int.parse(responseCode), content: parseSchemaOrRef(schema)),
  ];
}

Components parseComponents(MapContext json) {
  final keys = json.keys.toList();
  final supportedKeys = ['schemas', 'securitySchemes', 'requestBodies'];

  for (final key in keys) {
    if (!supportedKeys.contains(key)) {
      final value = json[key] as Json;
      if (value.isNotEmpty) {
        throw UnimplementedError('Components key not supported: $key');
      }
    }
  }

  final securitySchemesJson = json['securitySchemes'] as Json?;
  if (securitySchemesJson != null) {
    logger.warn('Ignoring securitySchemes.');
  }

  final schemasJson = _optionalMap(json, 'schemas');
  final schemas = <String, Schema>{};
  if (schemasJson != null) {
    for (final name in schemasJson.keys) {
      final snakeName = snakeFromCamel(name);
      final childContext = schemasJson
          .childAsMap(name)
          .addSnakeName(snakeName, isTopLevelComponent: true);
      final ref = parseSchemaOrRef(childContext);
      final schema = ref.schema;
      if (schema == null) {
        throw UnimplementedError(
          'reference found, schema expected: ${childContext.pointer}',
        );
      }
      schemas[name] = schema;
    }
  }

  final requestBodiesJson = json['requestBodies'] as Json?;
  final requestBodies = <String, RequestBody>{};
  if (requestBodiesJson != null) {
    for (final name in requestBodiesJson.keys) {
      final snakeName = snakeFromCamel(name);
      final childContext = json
          .addSnakeName(snakeName, isTopLevelComponent: true)
          .childAsMap('requestBodies')
          .childAsMap(name);
      requestBodies[name] = parseRequestBody(childContext);
    }
  }

  return Components(schemas: schemas, requestBodies: requestBodies);
}

Info parseInfo(MapContext json) {
  final title = _required<String>(json, 'title');
  final version = _required<String>(json, 'version');
  _ignored(json, 'summary');
  _ignored(json, 'description');
  _ignored(json, 'termsOfService');
  _ignored(json, 'contact');
  _ignored(json, 'license');
  return Info(title, version);
}

OpenApi parseOpenApi(MapContext json) {
  final minimumVersion = Version.parse('3.1.0');
  final versionString = _required<String>(json, 'openapi');
  final version = Version.parse(versionString);
  if (version < minimumVersion) {
    _warn(json, '$version may not be supported, only tested with 3.1.0');
  }

  final info = parseInfo(_requiredMap(json, 'info'));

  final servers = _requiredList(json, 'servers');
  final firstServer = servers.indexAsMap(0);
  final serverUrl = _required<String>(firstServer, 'url');

  final paths = _requiredMap(json, 'paths');
  final endpoints = <Endpoint>[];
  for (final path in paths.keys) {
    final pathContext = paths.childAsMap(path);
    _expect(path.isNotEmpty, pathContext, 'Path cannot be empty');
    _expect(path.startsWith('/'), pathContext, 'Path must start with /: $path');
    for (final method in Method.values) {
      final methodValue = _optionalMap(pathContext, method.key);
      if (methodValue == null) {
        continue;
      }
      endpoints.add(
        parseEndpoint(json: methodValue, path: path, method: method),
      );
    }
  }
  final componentsJson = _optionalMap(json, 'components');
  final components = componentsJson == null
      ? const Components(schemas: {}, requestBodies: {})
      : parseComponents(componentsJson);
  return OpenApi(
    serverUrl: Uri.parse(serverUrl),
    version: version,
    info: info,
    endpoints: endpoints,
    components: components,
  );
}

class RefRegistry {
  RefRegistry();

  final objectsByUri = <Uri, dynamic>{};

  Iterable<Uri> get uris => objectsByUri.keys;

  T get<T>(Uri uri) {
    final object = objectsByUri[uri];
    if (object == null) {
      throw StateError('$T not found: $uri');
    }
    if (object is! T) {
      throw StateError('Expected $T, got $object');
    }
    return object;
  }

  void register(Uri uri, dynamic object) {
    if (objectsByUri.containsKey(uri)) {
      logger
        ..warn('Object already registered: $uri')
        ..info('before: ${objectsByUri[uri]}')
        ..info('after: $object');
      throw Exception('Object already registered: $uri');
    }
    if (object is Schema) {
      final schema = object;
      final byName = objectsByUri.entries
          .where((e) => e.value is Schema)
          .firstWhereOrNull(
            (e) => (e.value as Schema).snakeName == schema.snakeName,
          );
      if (byName != null) {
        logger
          ..warn('Schema already registered by name: ${schema.snakeName}')
          ..info('existing uri: ${byName.key}')
          ..info('existing schema: ${byName.value}')
          ..info('new uri: $uri')
          ..info('new schema: $schema');
      }
    }
    objectsByUri[uri] = object;
  }
}

/// Json pointer is a string that can be used to reference a value in a json
/// object.
/// https://spec.openapis.org/oas/v3.1.0#json-pointer
@immutable
class JsonPointer extends Equatable {
  /// Create a new JsonPointer from a list of parts.
  const JsonPointer(this.parts);

  /// The parts of the json pointer.
  final List<String> parts;

  /// This pointer encoded as a url-ready string.
  String get location => '/${parts.map(urlEncode).join('/')}';

  /// Encode a part of the json pointer as a url-ready string.
  static String urlEncode(String part) =>
      part.replaceAll('~', '~0').replaceAll('/', '~1');

  @override
  String toString() => '/${parts.join('/')}';

  @override
  List<Object?> get props => [parts];
}

class MapContext extends ParseContext {
  MapContext({
    required super.baseUrl,
    required super.pointerParts,
    required super.snakeNameStack,
    required super.refRegistry,
    required super.isTopLevelComponent,
    required this.json,
  });

  MapContext.fromParent({
    required ParseContext parent,
    required Map<String, dynamic> json,
    required String key,
  }) : this(
         baseUrl: parent.baseUrl,
         pointerParts: [...parent.pointerParts, key],
         snakeNameStack: parent.snakeNameStack,
         refRegistry: parent.refRegistry,
         isTopLevelComponent: parent.isTopLevelComponent,
         json: json,
       );

  MapContext.initial(Uri baseUrl, Json json)
    : this(
        baseUrl: baseUrl,
        pointerParts: [],
        snakeNameStack: [],
        refRegistry: RefRegistry(),
        isTopLevelComponent: true,
        json: json,
      );

  MapContext childAsMap(String key) {
    final value = json[key];
    if (value == null) {
      throw StateError('Key not found: $key in $pointer');
    }
    if (value is! Map<String, dynamic>) {
      throw FormatException(
        'Key $key is not of type Map<String, dynamic> '
        'rather ${value.runtimeType}: $value (in $pointer)',
      );
    }
    return MapContext.fromParent(parent: this, json: value, key: key);
  }

  ListContext childAsList(String key) {
    final value = json[key];
    if (value == null) {
      throw StateError('Key not found: $key in $pointer');
    }
    if (value is! List) {
      throw FormatException(
        'Key $key is not of type List: $value (in $pointer)',
      );
    }
    return ListContext.fromParent(parent: this, json: value, key: key);
  }

  MapContext addSnakeName(
    String snakeName, {
    bool isTopLevelComponent = false,
  }) => MapContext(
    baseUrl: baseUrl,
    pointerParts: pointerParts,
    snakeNameStack: [...snakeNameStack, snakeName],
    refRegistry: refRegistry,
    isTopLevelComponent: isTopLevelComponent,
    json: json,
  );

  dynamic operator [](String key) => json[key];

  bool containsKey(String key) {
    final json = this.json;
    return json.containsKey(key);
  }

  Iterable<String> get keys => json.keys;

  bool isEmpty() => json.isEmpty;

  final Json json;
}

class ListContext extends ParseContext {
  ListContext({
    required super.baseUrl,
    required super.pointerParts,
    required super.snakeNameStack,
    required super.refRegistry,
    required super.isTopLevelComponent,
    required this.json,
  });

  ListContext.fromParent({
    required ParseContext parent,
    required List<dynamic> json,
    required String key,
  }) : this(
         baseUrl: parent.baseUrl,
         pointerParts: [...parent.pointerParts, key],
         snakeNameStack: parent.snakeNameStack,
         refRegistry: parent.refRegistry,
         isTopLevelComponent: parent.isTopLevelComponent,
         json: json,
       );

  ListContext indexAsList(int index) {
    final value = json[index];
    if (value == null) {
      throw FormatException('Index not found: $index in $pointer');
    }
    if (value is! List<dynamic>) {
      throw FormatException(
        'Index $index is not of type List<dynamic>: $value (in $pointer)',
      );
    }
    return ListContext.fromParent(
      parent: this,
      json: value,
      key: index.toString(),
    );
  }

  MapContext indexAsMap(int index) {
    final value = json[index];
    if (value == null) {
      throw FormatException('Index not found: $index in $pointer');
    }
    if (value is! Map<String, dynamic>) {
      throw FormatException(
        'Index $index is not of type Map<String, dynamic>: $value (in $pointer)',
      );
    }
    return MapContext.fromParent(
      parent: this,
      json: value,
      key: index.toString(),
    );
  }

  dynamic operator [](int index) => json[index];

  int get length => json.length;

  Iterable<(int, dynamic)> get indexed => json.indexed;

  ListContext addSnakeName(
    String snakeName, {
    bool isTopLevelComponent = false,
  }) => ListContext(
    baseUrl: baseUrl,
    pointerParts: pointerParts,
    snakeNameStack: [...snakeNameStack, snakeName],
    refRegistry: refRegistry,
    isTopLevelComponent: isTopLevelComponent,
    json: json,
  );

  final List<dynamic> json;
}

/// Immutable context for parsing a spec.
/// SchemaRegistry is internally mutable, so this is not truly immutable.
abstract class ParseContext {
  ParseContext({
    required this.baseUrl,
    required this.pointerParts,
    required this.snakeNameStack,
    required this.refRegistry,
    required this.isTopLevelComponent,
  }) {
    if (baseUrl.hasFragment) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'Base url cannot have a fragment',
      );
    }
  }

  /// The base url of the spec being parsed.
  final Uri baseUrl;

  /// Json pointer location of the current schema.
  final List<String> pointerParts;

  /// Stack of name parts for the current schema.
  final List<String> snakeNameStack;

  /// Whether the current schema is a top-level component.
  final bool isTopLevelComponent;

  JsonPointer get pointer => JsonPointer(pointerParts);

  String get snakeName {
    // To match OpenAPI, we don't put a _ before numbers.
    final buf = StringBuffer();
    for (final e in snakeNameStack) {
      if (buf.isNotEmpty && (e.isNotEmpty && int.tryParse(e[0]) == null)) {
        buf.write('_');
      }
      buf.write(e);
    }
    return buf.toString();
  }

  // Registry of all the schemas we've parsed so far.
  // RefRegistry is internally mutable.
  final RefRegistry refRegistry;

  void addObject(dynamic object) {
    final uri = baseUrl.replace(fragment: pointer.toString());
    refRegistry.register(uri, object);
  }
}
