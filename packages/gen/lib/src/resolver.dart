import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:space_gen/src/loader.dart';
import 'package:space_gen/src/spec.dart';

export 'package:space_gen/src/spec.dart' show SchemaType;

/// Resolves a JSON pointer into a JSON object.
///
/// The pointer is a string of the form `/path/to/object`.
/// The object is the root object of the JSON document.
/// The pointer is the path to the object in the JSON document.
Json resolvePointerToObject(Json json, String pointer) {
  // If the pointer is empty, split will return a list with an empty string.
  final parts = pointer.split('/');
  if (pointer.isEmpty || parts.isEmpty) {
    return json;
  }
  var i = 0;
  dynamic current = json;
  while (i < parts.length) {
    final part = parts[i];
    // Expect the first part to be empty and skip it.
    if (i == 0) {
      if (part != '') {
        throw Exception('Pointer must start with a slash: $pointer');
      }
      i++;
      continue;
    }
    // Handle the part based on the type of the current object.
    if (current is Json) {
      current = current[part];
    } else if (current is List) {
      current = current[int.parse(part)];
    } else {
      throw Exception('Invalid pointer: $pointer');
    }
    i++;
  }
  if (current is! Json) {
    throw Exception('Invalid pointer: $pointer');
  }
  return current;
}

@immutable
class _NamingContext {
  const _NamingContext(this.stack);

  final List<String> stack;

  _NamingContext append(String name) => _NamingContext(stack + [name]);

  String get name => stack.join('_');
}

/// Takes a Spec object and resolves it into a ResolvedSpec object.
class Resolver {
  Resolver({required this.baseUrl, required SchemaRegistry registry})
    : _schemas = registry;

  final Uri baseUrl;
  final SchemaRegistry _schemas;
  final Map<Uri, ResolvedSchema> _resolvedByUri = {};
  final Map<Schema, ResolvedSchema> _resolvedByContent = {};

  ResolvedSchema? _byUri(Uri uri) {
    final cached = _resolvedByUri[uri];
    if (cached != null) {
      return cached;
    }
    final schema = _schemas[uri];
    return _byContent(schema);
  }

  ResolvedSchema? _byContent(Schema schema) {
    return _resolvedByContent[schema];
  }

  /// Resolve a schema from a URI.
  ResolvedSchema _schema(Uri uri, _NamingContext parentNaming) {
    final cached = _byUri(uri);
    if (cached != null) {
      return cached;
    }

    final schema = _schemas.schemas[uri];
    if (schema == null) {
      throw Exception('Schema not found in registry: $uri');
    }
    final resolved = _createSchema(schema, parentNaming);
    _resolvedByUri[uri] = resolved;
    _resolvedByContent[schema] = resolved;
    return resolved;
  }

  /// Callers should always use _schema rather than calling this directly.
  ResolvedSchema _createSchema(Schema schema, _NamingContext parentNaming) {
    final naming = parentNaming.append('inner');
    return ResolvedSchema(
      // TODO(eseidel): This should be "inner" right?
      name: naming.name,
      type: schema.type,
      properties: Map<String, ResolvedSchema>.fromEntries(
        schema.properties.entries.map(
          (e) => MapEntry(e.key, _ref(e.value, naming)),
        ),
      ),
      required: schema.required,
      description: schema.description,
      items: _maybeRef(schema.items, naming),
      enumValues: schema.enumValues,
      format: schema.format,
    );
  }

  ResolvedSpec resolveSpec(Spec spec) {
    // References could be circular, so we should walk them all and put them
    // into a queue.  However SpaceTraders has no circular references, so we
    // don't bother.
    const naming = _NamingContext([]);
    return ResolvedSpec(
      serverUrl: spec.serverUrl,
      endpoints: spec.endpoints.map((e) => _endpoint(e, naming)).toList(),
    );
  }

  ResolvedSchema? _maybeRef(SchemaRef? ref, _NamingContext parentNaming) =>
      ref == null ? null : _ref(ref, parentNaming);

  ResolvedSchema _ref(SchemaRef ref, _NamingContext parentNaming) {
    final maybeSchema = ref.schema;
    if (maybeSchema != null) {
      print(parentNaming.name);
      final uri = _schemas.lookupUri(maybeSchema);
      return _schema(uri, parentNaming);
    }
    final uri = ref.uri;
    if (uri == null) {
      throw Exception('SchemaRef has no uri: $ref');
    }
    // TODO(eseidel): This isn't correct for multi-file specs.
    final parsed = baseUrl.resolve(uri);
    return _schema(parsed, parentNaming);
  }

  ResolvedParameter _parameter(
    Parameter parameter,
    _NamingContext parentNaming,
  ) {
    final p = parameter;
    return ResolvedParameter(
      isRequired: p.isRequired,
      sentIn: p.sentIn,
      name: p.name,
      type: _ref(p.type, parentNaming),
    );
  }

  ResolvedResponse _response(Response response, _NamingContext parentNaming) {
    final naming = parentNaming.append(response.code.toString());
    return ResolvedResponse(
      code: response.code,
      content: _ref(response.content, naming),
    );
  }

  ResolvedEndpoint _endpoint(Endpoint endpoint, _NamingContext parentNaming) {
    final e = endpoint;
    final naming = parentNaming.append(e.snakeName);
    return ResolvedEndpoint(
      path: e.path,
      method: e.method,
      tag: e.tag,
      responses: e.responses.map((r) => _response(r, naming)).toList(),
      snakeName: e.snakeName,
      parameters: e.parameters.map((p) => _parameter(p, naming)).toList(),
      requestBody: _maybeRef(e.requestBody, naming),
    );
  }
}

/// Top level object in an OpenAPI spec.
class ResolvedSpec {
  ResolvedSpec({required this.serverUrl, required this.endpoints});

  final Uri serverUrl;
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
    required this.name,
    required this.type,
    required this.properties,
    required this.required,
    required this.description,
    required this.items,
    required this.enumValues,
    required this.format,
  });

  /// Name is inferred during the resolve process.
  final String name;

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
