import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:space_gen/src/loader.dart';
import 'package:space_gen/src/spec.dart';

export 'package:space_gen/src/spec.dart' show SchemaType;

/// A registry of all the specs that have been resolved.
class SchemaRegistry {
  SchemaRegistry(this.fs, this.baseUrl);

  final FileSystem fs;
  final Uri baseUrl;

  final Map<Uri, Schema> _schemas = {};

  Schema get(Uri uri) {
    if (_schemas.containsKey(uri)) {
      return _schemas[uri]!;
    }
    final file = fs.file(uri.toFilePath());
    final contents = file.readAsStringSync();
    final schema = Schema.fromJson(
      jsonDecode(contents) as Map<String, dynamic>,
    );
    _schemas[uri] = schema;
    return schema;
  }
}

/// Takes a Spec object and resolves it into a ResolvedSpec object.
class Resolver {
  Resolver(this.fs, this.baseUrl, this.cache);

  final FileSystem fs;
  final Uri baseUrl;
  final Cache cache;

  ResolvedSpec resolveSpec(Spec spec) {
    // References could be circular, so we should walk them all and put them
    // into a queue.  However SpaceTraders has no circular references, so we
    // don't bother.
    final schemas = SchemaRegistry(fs, baseUrl);
    return ResolvedSpec(
      schemas: schemas,
      serverUrl: spec.serverUrl,
      endpoints: spec.endpoints.map(_endpoint).toList(),
    );
  }

  ResolvedSchema? _maybeRef(SchemaRef? ref) => ref == null ? null : _ref(ref);

  ResolvedSchema _ref(SchemaRef ref) {
    if (ref.schema != null) {
      return _schema(ref.schema!);
    }
    final uri = ref.uri;
    if (uri == null) {
      throw Exception('SchemaRef has no uri: $ref');
    }
    // TODO(eseidel): This isn't correct for multi-file specs.
    final parsed = baseUrl.resolve(uri);
    final json = cache.get(parsed);
    if (json == null) {
      throw Exception('Schema not found in cache: $parsed');
    }
    return _schema(Schema.fromJson(json));
  }

  ResolvedSchema _schema(Schema schema) {
    return ResolvedSchema(
      type: schema.type,
      properties: Map<String, ResolvedSchema>.fromEntries(
        schema.properties.entries.map((e) => MapEntry(e.key, _ref(e.value))),
      ),
      required: schema.required,
      description: schema.description,
      items: _maybeRef(schema.items),
      enumValues: schema.enumValues,
      format: schema.format,
    );
  }

  ResolvedParameter _parameter(Parameter parameter) {
    final p = parameter;
    return ResolvedParameter(
      isRequired: p.isRequired,
      sentIn: p.sentIn,
      name: p.name,
      type: _ref(p.type),
    );
  }

  ResolvedResponse _response(Response response) {
    return ResolvedResponse(
      code: response.code,
      content: _ref(response.content),
    );
  }

  ResolvedEndpoint _endpoint(Endpoint endpoint) {
    final e = endpoint;
    return ResolvedEndpoint(
      path: e.path,
      method: e.method,
      tag: e.tag,
      responses: e.responses.map(_response).toList(),
      snakeName: e.snakeName,
      parameters: e.parameters.map(_parameter).toList(),
      requestBody: _maybeRef(e.requestBody),
    );
  }
}

/// Top level object in an OpenAPI spec.
class ResolvedSpec {
  ResolvedSpec({
    required this.serverUrl,
    required this.schemas,
    required this.endpoints,
  });

  final Uri serverUrl;
  final SchemaRegistry schemas;
  final List<ResolvedEndpoint> endpoints;

  List<String> get tags => endpoints.map((e) => e.tag).toSet().sorted();
}

/// A parameter to an endpoint.
class ResolvedParameter {
  ResolvedParameter({
    required this.isRequired,
    required this.sentIn,
    required this.name,
    required this.type,
  });

  final bool isRequired;
  final SentIn sentIn;
  final String name;
  final ResolvedSchema type;
}

/// A response from an endpoint.
class ResolvedResponse {
  ResolvedResponse({required this.code, required this.content});

  final int code;
  final ResolvedSchema content;
}

/// A schema in an OpenAPI spec.  This is the resolved version of a SchemaRef.
/// These are typically rendered as classes.
class ResolvedSchema {
  ResolvedSchema({
    required this.type,
    required this.properties,
    required this.required,
    required this.description,
    required this.items,
    required this.enumValues,
    required this.format,
  });

  final SchemaType type;
  final Map<String, ResolvedSchema> properties;
  final List<String> required;
  final String description;
  final ResolvedSchema? items;
  final List<String> enumValues;
  final String? format;
}

/// An endpoint in an OpenAPI spec. This is the resolved version of an Endpoint.
/// These are typically rendered as methods on an "API" class which corresponds
/// to a tag (set of endpoints) in the spec.
class ResolvedEndpoint {
  ResolvedEndpoint({
    required this.path,
    required this.method,
    required this.tag,
    required this.responses,
    required this.snakeName,
    required this.parameters,
    required this.requestBody,
  });

  final String path;
  final Method method;
  final String tag;
  final List<ResolvedResponse> responses;
  final String snakeName;
  final List<ResolvedParameter> parameters;
  final ResolvedSchema? requestBody;
}

// class RefResolver {
//   RefResolver(FileSystem fs, this.baseUrl) : _fs = fs;
//   final Uri baseUrl;
//   final FileSystem _fs;
//   final Map<Uri, Schema> _schemas = {};

//   Schema resolve(SchemaRef ref) {
//     if (ref.schema != null) {
//       return ref.schema!;
//     }
//     final uri = ref.uri!;
//     if (_schemas.containsKey(uri)) {
//       return _schemas[uri]!;
//     }
//     print(uri);
//     final file = _fs.file(uri.toFilePath());
//     final contents = file.readAsStringSync();
//     final schema = parseSchema(
//       current: uri,
//       name: p.basenameWithoutExtension(uri.path),
//       json: jsonDecode(contents) as Map<String, dynamic>,
//     );
//     _schemas[uri] = schema;
//     return schema;
//   }
// }
