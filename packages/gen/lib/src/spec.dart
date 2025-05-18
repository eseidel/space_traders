import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:space_gen/src/string.dart';

enum SentIn {
  query,
  header,
  path,
  cookie;

  static SentIn fromJson(String json) {
    switch (json) {
      case 'query':
        return query;
      case 'header':
        return header;
      case 'path':
        return path;
      case 'cookie':
        return cookie;
      default:
        throw ArgumentError.value(json, 'json', 'Unknown SentIn');
    }
  }
}

class Parameter {
  const Parameter({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.sentIn,
  });

  factory Parameter.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final required = json['required'] as bool? ?? false;
    final sentIn = json['in'] as String;
    final schema = json['schema'] as Map<String, dynamic>;
    final type = parseSchemaOrRef(json: schema);
    return Parameter(
      name: name,
      isRequired: required,
      sentIn: SentIn.fromJson(sentIn),
      type: type,
    );
  }

  final bool isRequired;
  final SentIn sentIn;
  final String name;
  final SchemaRef type;
}

class Tag {
  const Tag({required this.name, required this.endpoints});

  final String name;
  final List<Endpoint> endpoints;
}

enum SchemaType {
  string,
  number,
  integer,
  boolean,
  array,
  object;

  static SchemaType fromJson(String json) {
    switch (json) {
      case 'string':
        return string;
      case 'number':
        return number;
      case 'integer':
        return integer;
      case 'boolean':
        return boolean;
      case 'array':
        return array;
      case 'object':
        return object;
      default:
        throw ArgumentError.value(json, 'json', 'Unknown SchemaType');
    }
  }
}

@immutable
class SchemaRef {
  const SchemaRef.fromPath({required String ref}) : schema = null, uri = ref;
  const SchemaRef.schema(this.schema) : uri = null;

  final String? uri;
  final Schema? schema;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemaRef &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          schema == other.schema;

  @override
  int get hashCode => Object.hash(uri, schema);
}

// https://spec.openapis.org/oas/v3.0.0#schemaObject
class Schema {
  const Schema({
    required this.type,
    required this.properties,
    required this.required,
    required this.description,
    required this.items,
    required this.enumValues,
    required this.format,
  });

  factory Schema.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final properties = parseProperties(
      json: json['properties'] as Map<String, dynamic>?,
    );
    final items = json['items'] as Map<String, dynamic>?;
    SchemaRef? itemSchema;
    if (items != null) {
      itemSchema = parseSchemaOrRef(json: items);
    }

    final required = json['required'] as List<dynamic>? ?? [];
    final description = json['description'] as String? ?? '';
    final enumValues = json['enum'] as List<dynamic>? ?? [];
    final format = json['format'] as String?;

    return Schema(
      type: SchemaType.fromJson(type),
      properties: properties,
      required: required.cast<String>(),
      description: description,
      items: itemSchema,
      enumValues: enumValues.cast<String>(),
      format: format,
    );
  }

  final SchemaType type;
  final Map<String, SchemaRef> properties;
  final List<String> required;
  final String description;
  final SchemaRef? items;
  final List<String> enumValues;
  final String? format;
}

/// Parse a schema or a reference to a schema.
SchemaRef parseSchemaOrRef({required Map<String, dynamic> json}) {
  if (json.containsKey(r'$ref')) {
    return SchemaRef.fromPath(ref: json[r'$ref'] as String);
  }

  if (json.containsKey('oneOf')) {
    // TODO(eseidel): Support oneOf
    return const SchemaRef.schema(
      Schema(
        description: 'OneOf',
        type: SchemaType.object,
        properties: {},
        required: [],
        items: null,
        enumValues: [],
        format: null,
      ),
    );
  }

  if (json.containsKey('allOf')) {
    final allOf = json['allOf'] as List<dynamic>;
    if (allOf.length != 1) {
      throw UnimplementedError('AllOf with ${allOf.length} items');
    }
    return parseSchemaOrRef(json: allOf.first as Map<String, dynamic>);
  }

  return SchemaRef.schema(Schema.fromJson(json));
}

Map<String, SchemaRef> parseProperties({required Map<String, dynamic>? json}) {
  if (json == null) {
    return {};
  }
  final properties = <String, SchemaRef>{};
  if (json.isEmpty) {
    return properties;
  }
  for (final entry in json.entries) {
    final name = entry.key;
    final value = entry.value as Map<String, dynamic>;
    properties[name] = parseSchemaOrRef(json: value);
  }
  return properties;
}

enum Method {
  get,
  post,
  put,
  delete,
  patch,
  head,
  options,
  trace;

  String get key => name.toLowerCase();
}

// https://spec.openapis.org/oas/v3.0.0#path-item-object
class Endpoint {
  const Endpoint({
    required this.path,
    required this.method,
    required this.tag,
    required this.responses,
    required this.parameters,
    required this.snakeName,
    required this.requestBody,
  });

  final String path;
  final Method method;
  final String tag;
  final List<Response> responses;
  final String snakeName;
  final List<Parameter> parameters;
  final SchemaRef? requestBody;
}

class Response {
  const Response({required this.code, required this.content});

  final int code;
  // The official spec has a map here by mime type, but we only support json.
  final SchemaRef content;
}

List<Response> parseResponses(Map<String, dynamic> json, String camelName) {
  // Hack to make get cooldown compile.
  final responseCodes = json.keys.toList()..remove('204');
  if (responseCodes.length != 1) {
    throw UnimplementedError('Multiple responses not supported, $camelName');
  }

  final responseCode = responseCodes.first;
  final responseTypes = json[responseCode] as Map<String, dynamic>;
  final content = responseTypes['content'] as Map<String, dynamic>?;
  if (content == null) {
    return [
      Response(
        code: int.parse(responseCode),
        content: const SchemaRef.schema(
          // This is a hack, this should just be a string.
          Schema(
            type: SchemaType.object,
            properties: {},
            required: [],
            description: '',
            items: null,
            enumValues: [],
            format: null,
          ),
        ),
      ),
    ];
  }
  final jsonResponse = content['application/json'] as Map<String, dynamic>;
  return [
    Response(
      code: int.parse(responseCode),
      content: parseSchemaOrRef(
        json: jsonResponse['schema'] as Map<String, dynamic>,
      ),
    ),
  ];
}

Endpoint parseEndpoint(
  Map<String, dynamic> methodValue,
  String path,
  Method method,
) {
  final snakeName =
      methodValue['operationId'] as String? ??
      Uri.parse(path).pathSegments.last;

  final camelName = snakeName.splitMapJoin(
    '-',
    onMatch: (m) => '',
    onNonMatch: (n) => n.capitalize(),
  );

  final responses = parseResponses(
    methodValue['responses'] as Map<String, dynamic>,
    camelName,
  );
  final tags = methodValue['tags'] as List<dynamic>?;
  final tag = tags?.firstOrNull as String? ?? 'Default';
  final parametersJson = methodValue['parameters'] as List<dynamic>? ?? [];
  final parameters =
      parametersJson
          .cast<Map<String, dynamic>>()
          .map(Parameter.fromJson)
          .toList();
  final requestBodyJson = methodValue['requestBody'] as Map<String, dynamic>?;
  SchemaRef? requestBody;
  if (requestBodyJson != null) {
    final content = requestBodyJson['content'] as Map<String, dynamic>;
    final json = content['application/json'] as Map<String, dynamic>;
    requestBody = parseSchemaOrRef(
      json: json['schema'] as Map<String, dynamic>,
    );
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

// Spec calls this the "OpenAPI Object"
// https://spec.openapis.org/oas/v3.1.0#openapi-object
class Spec {
  Spec(this.serverUrl, this.endpoints);

  factory Spec.fromJson(Map<String, dynamic> json) {
    final servers = json['servers'] as List<dynamic>;
    final firstServer = servers.first as Map<String, dynamic>;
    final serverUrl = firstServer['url'] as String;

    final paths = json['paths'] as Map<String, dynamic>;
    final endpoints = <Endpoint>[];
    for (final pathEntry in paths.entries) {
      final path = pathEntry.key;
      final pathValue = pathEntry.value as Map<String, dynamic>;
      for (final method in Method.values) {
        final methodValue = pathValue[method.key] as Map<String, dynamic>?;
        if (methodValue == null) {
          continue;
        }
        endpoints.add(parseEndpoint(methodValue, path, method));
      }
    }
    return Spec(Uri.parse(serverUrl), endpoints);
  }

  final Uri serverUrl;
  final List<Endpoint> endpoints;

  List<String> get tags => endpoints.map((e) => e.tag).toSet().sorted();
}
