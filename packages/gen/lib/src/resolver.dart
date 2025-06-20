// The job here is to walk the spec and resolve all the references.
// This also creates a tree that is more designed for rendering rather
// than serialization/deserialization with the openapi spec.
// This also discards all non-json values.

import 'package:equatable/equatable.dart';
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/parser.dart';
import 'package:space_gen/src/spec.dart';
import 'package:space_gen/src/visitor.dart';

void _warn(String message, JsonPointer pointer) {
  logger.warn('$message in $pointer');
}

class _ResolveContext {
  _ResolveContext({required this.specUrl, required this.refRegistry});

  /// The spec url of the spec.
  final Uri specUrl;

  /// The registry of all the objects we've parsed so far.
  final RefRegistry refRegistry;

  /// The registry of all the objects we've parsed so far.
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
}

List<ResolvedPath> _resolvePaths(Paths paths, _ResolveContext context) {
  return paths.paths.entries.map((entry) {
    final path = entry.key;
    final pathItem = entry.value;
    return ResolvedPath(
      path: path,
      operations: _resolveOperations(pathItem, context),
    );
  }).toList();
}

ResolvedSchema? _maybeResolveSchema(SchemaRef? ref, _ResolveContext context) {
  if (ref == null) {
    return null;
  }
  return _resolveSchema(ref, context);
}

ResolvedSchema _resolveSchema(SchemaRef ref, _ResolveContext context) {
  final schema = context._maybeResolve(ref);
  if (schema == null) {
    throw Exception('Schema not found: $ref');
  }
  if (schema is Schema) {
    if (schema.type == SchemaType.object) {
      return SchemaObject(
        pointer: schema.pointer,
        properties: schema.properties.map((key, value) {
          return MapEntry(key, _resolveSchema(value, context));
        }),
        snakeName: schema.snakeName,
        additionalProperties: _maybeResolveSchema(
          schema.additionalProperties,
          context,
        ),
        required: schema.required,
      );
    }
    if (schema.type == SchemaType.string) {
      if (schema.enumValues.isNotEmpty) {
        return SchemaEnum(
          pointer: schema.pointer,
          defaultValue: schema.defaultValue,
          values: schema.enumValues,
          snakeName: schema.snakeName,
        );
      }
      return SchemaPod(
        type: PodType.string,
        pointer: schema.pointer,
        snakeName: schema.snakeName,
        defaultValue: schema.defaultValue,
      );
    }
    if (schema.type == SchemaType.integer) {
      return SchemaPod(
        type: PodType.integer,
        pointer: schema.pointer,
        snakeName: schema.snakeName,
        defaultValue: schema.defaultValue,
      );
    }
    if (schema.type == SchemaType.number) {
      return SchemaPod(
        type: PodType.number,
        pointer: schema.pointer,
        snakeName: schema.snakeName,
        defaultValue: schema.defaultValue,
      );
    }
    if (schema.type == SchemaType.boolean) {
      return SchemaPod(
        type: PodType.boolean,
        pointer: schema.pointer,
        snakeName: schema.snakeName,
        defaultValue: schema.defaultValue,
      );
    }
    if (schema.type == SchemaType.array) {
      return SchemaArray(
        items: _maybeResolveSchema(schema.items, context),
        snakeName: schema.snakeName,
        pointer: schema.pointer,
        defaultValue: schema.defaultValue,
      );
    }
    if (schema.type == SchemaType.unknown) {
      return SchemaUnknown(
        snakeName: schema.snakeName,
        pointer: schema.pointer,
      );
    }
  }
  throw Exception('Schema is not a single schema: $schema');
}

ResolvedRequestBody? _resolveRequestBody(
  RefOr<RequestBody>? ref,
  _ResolveContext context,
) {
  if (ref == null) {
    return null;
  }
  final requestBody = context._maybeResolve(ref);
  if (requestBody == null) {
    throw Exception('Request body not found: $ref');
  }
  final jsonSchema = requestBody.content['application/json']?.schema;
  if (jsonSchema == null) {
    throw Exception('Request body is not json: $ref');
  }
  return ResolvedRequestBody(
    schema: _resolveSchema(jsonSchema, context),
    description: requestBody.description,
    required: requestBody.isRequired,
  );
}

List<ResolvedParameter> _resolveParameters(
  List<RefOr<Parameter>> parameters,
  _ResolveContext context,
) {
  return parameters.map((parameter) {
    final resolved = context._resolve(parameter);
    return ResolvedParameter(
      name: resolved.name,
      sendIn: resolved.sendIn,
      description: resolved.description,
      required: resolved.isRequired,
      schema: _resolveSchema(resolved.type, context),
    );
  }).toList();
}

List<ResolvedOperation> _resolveOperations(
  PathItem pathItem,
  _ResolveContext context,
) {
  return pathItem.operations.entries.map((entry) {
    final method = entry.key;
    final operation = entry.value;
    final requestBody = _resolveRequestBody(operation.requestBody, context);
    final responses = _resolveResponses(operation.responses, context);
    return ResolvedOperation(
      snakeName: operation.snakeName,
      tags: operation.tags,
      summary: operation.summary,
      description: operation.description,
      method: method,
      path: pathItem.path,
      requestBody: requestBody,
      responses: responses,
      parameters: _resolveParameters(operation.parameters, context),
    );
  }).toList();
}

ResolvedSchema _resolveContent(Response response, _ResolveContext context) {
  final content = response.content;
  // Should this just be a void response?
  if (content == null) {
    return SchemaVoid(snakeName: 'void', pointer: response.pointer);
  }
  if (content.isEmpty) {
    _warn('Response has no content: $response', response.pointer);
    return SchemaVoid(snakeName: 'void', pointer: response.pointer);
  }
  final jsonSchema = content['application/json']?.schema;
  if (jsonSchema != null) {
    return _resolveSchema(jsonSchema, context);
  }
  _warn('Response has no application/json schema: $response', response.pointer);
  return _resolveSchema(content.values.first.schema, context);
}

List<ResolvedResponse> _resolveResponses(
  Responses responses,
  _ResolveContext context,
) {
  return responses.responses.entries.map((entry) {
    final statusCode = entry.key;
    final response = context._resolve(entry.value);

    return ResolvedResponse(
      statusCode: statusCode,
      description: response.description,
      content: _resolveContent(response, context),
    );
  }).toList();
}

class RegistryBuilder extends Visitor {
  RegistryBuilder(this.spec, this.refRegistry);
  final OpenApi spec;
  final RefRegistry refRegistry;

  void add(HasPointer object) {
    final uri = spec.serverUrl.replace(fragment: object.pointer.location);
    refRegistry.register(uri, object);
  }

  @override
  void visitPathItem(PathItem pathItem) => add(pathItem);
  @override
  void visitOperation(Operation operation) => add(operation);
  @override
  void visitParameter(Parameter parameter) => add(parameter);
  @override
  void visitResponse(Response response) => add(response);
  @override
  void visitRequestBody(RequestBody requestBody) => add(requestBody);
  @override
  void visitSchema(SchemaBase schema) => add(schema);
  @override
  void visitHeader(Header header) => add(header);
}

ResolvedSpec resolveSpec(OpenApi spec) {
  final refRegistry = RefRegistry();
  final builder = RegistryBuilder(spec, refRegistry);
  SpecWalker(builder).walkRoot(spec);

  logger.detail('Registered schemas:');
  for (final uri in refRegistry.uris) {
    logger.detail('  - $uri');
  }

  final context = _ResolveContext(
    specUrl: spec.serverUrl,
    refRegistry: refRegistry,
  );
  return ResolvedSpec(
    serverUrl: spec.serverUrl,
    paths: _resolvePaths(spec.paths, context),
  );
}

class ResolvedSpec extends Equatable {
  const ResolvedSpec({required this.serverUrl, required this.paths});

  /// The server url of the spec.
  final Uri serverUrl;

  /// The paths of the spec.
  final List<ResolvedPath> paths;

  @override
  List<Object?> get props => [serverUrl, paths];
}

class ResolvedPath {
  const ResolvedPath({required this.path, required this.operations});

  /// The path of the resolved path.
  final String path;

  /// The operations of the resolved path.
  final List<ResolvedOperation> operations;
}

class ResolvedParameter extends Equatable {
  const ResolvedParameter({
    required this.name,
    required this.sendIn,
    required this.description,
    required this.required,
    required this.schema,
  });

  /// The name of the resolved parameter.
  final String name;

  /// The in of the resolved parameter.
  final SendIn sendIn;

  /// The description of the resolved parameter.
  final String? description;

  /// Whether the parameter is required.
  final bool required;

  /// The schema of the resolved parameter.
  final ResolvedSchema schema;

  @override
  List<Object?> get props => [name, sendIn, description, required, schema];
}

class ResolvedRequestBody extends Equatable {
  const ResolvedRequestBody({
    required this.schema,
    required this.description,
    required this.required,
  });

  /// The schema of the resolved request body.
  final ResolvedSchema schema;

  /// The description of the resolved request body.
  final String? description;

  /// Whether the request body is required.
  final bool required;

  @override
  List<Object?> get props => [schema];
}

class ResolvedOperation extends Equatable {
  const ResolvedOperation({
    required this.method,
    required this.path,
    required this.snakeName,
    required this.requestBody,
    required this.responses,
    required this.tags,
    required this.summary,
    required this.description,
    required this.parameters,
  });

  /// The method of the resolved operation.
  final Method method;

  /// The path of the resolved operation.
  final String path;

  /// The snake name of the resolved operation.
  final String snakeName;

  /// The parameters of the resolved operation.
  final List<ResolvedParameter> parameters;

  /// The request body of the resolved operation.
  final ResolvedRequestBody? requestBody;

  /// The responses of the resolved operation.
  final List<ResolvedResponse> responses;

  /// The tags of the resolved operation.
  final List<String> tags;

  /// The summary of the resolved operation.
  final String summary;

  /// The description of the resolved operation.
  final String? description;

  @override
  List<Object?> get props => [
    method,
    path,
    requestBody,
    responses,
    tags,
    summary,
    description,
  ];
}

class ResolvedResponse extends Equatable {
  const ResolvedResponse({
    required this.statusCode,
    required this.description,
    required this.content,
  });

  /// The status code of the resolved response.
  final int statusCode;

  /// The description of the resolved response.
  final String description;

  /// The resolved content of the resolved response.
  /// We only support json, so we only need a single content.
  final ResolvedSchema content;

  @override
  List<Object?> get props => [statusCode, description, content];
}

abstract class ResolvedSchema extends Equatable {
  const ResolvedSchema({required this.snakeName, required this.pointer});

  /// Where this schema is located in the spec.
  final JsonPointer pointer;

  /// The snake name of the resolved schema.
  final String snakeName;

  @override
  List<Object?> get props => [snakeName, pointer];
}

enum PodType { string, integer, number, boolean, dateTime }

class SchemaPod extends ResolvedSchema {
  const SchemaPod({
    required super.snakeName,
    required super.pointer,
    required this.defaultValue,
    required this.type,
  });

  /// The type of the resolved schema.
  final PodType type;

  /// The default value of the pop type.
  final dynamic defaultValue;

  @override
  List<Object?> get props => [super.props, type];
}

class SchemaArray extends ResolvedSchema {
  const SchemaArray({
    required super.pointer,
    required super.snakeName,
    required this.items,
    required this.defaultValue,
  });

  /// type of the items in the array
  final ResolvedSchema? items;

  /// The default value of the array type.
  final dynamic defaultValue;

  @override
  List<Object?> get props => [super.props, items];
}

class SchemaEnum extends ResolvedSchema {
  const SchemaEnum({
    required super.snakeName,
    required super.pointer,
    required this.defaultValue,
    required this.values,
  });

  /// The values of the resolved schema.
  final List<String> values;

  final dynamic defaultValue;
}

class SchemaObject extends ResolvedSchema {
  const SchemaObject({
    required this.properties,
    required super.snakeName,
    required this.additionalProperties,
    required this.required,
    required super.pointer,
  });

  /// The properties of the resolved schema.
  final Map<String, ResolvedSchema> properties;

  /// The value type when the schema is a map.
  // TODO(eseidel): Should this be a separate type?
  final ResolvedSchema? additionalProperties;

  /// The required properties of the resolved schema.
  final List<String> required;

  @override
  List<Object?> get props => [super.props, properties, additionalProperties];
}

/// An unknown schema, typically means empty (e.g. schema: {})
class SchemaUnknown extends ResolvedSchema {
  const SchemaUnknown({required super.snakeName, required super.pointer});
}

abstract class ResolvedSchemaCollection extends ResolvedSchema {
  const ResolvedSchemaCollection({
    required super.snakeName,
    required super.pointer,
    required this.schemas,
  });

  /// The schemas of the resolved schema collection.
  final List<ResolvedSchema> schemas;

  @override
  List<Object?> get props => [super.props, schemas];
}

class SchemaOneOf extends ResolvedSchemaCollection {
  const SchemaOneOf({
    required super.schemas,
    required super.snakeName,
    required super.pointer,
  });
}

class SchemaAnyOf extends ResolvedSchemaCollection {
  const SchemaAnyOf({
    required super.schemas,
    required super.snakeName,
    required super.pointer,
  });
}

class SchemaAllOf extends ResolvedSchemaCollection {
  const SchemaAllOf({
    required super.schemas,
    required super.snakeName,
    required super.pointer,
  });
}

class SchemaVoid extends ResolvedSchema {
  const SchemaVoid({required super.snakeName, required super.pointer});
}
