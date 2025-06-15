import 'package:space_gen/src/spec.dart';

/// Subclass this and override the methods you want to visit.
abstract class Visitor {
  void visitRoot(OpenApi root) {}
  void visitPathItem(PathItem pathItem) {}
  void visitOperation(Operation operation) {}
  void visitParameter(Parameter parameter) {}
  void visitResponse(Response response) {}
  void visitRequestBody(RequestBody requestBody) {}
  void visitReference<T>(RefOr<T> ref) {}
  void visitSchema(SchemaBase schema) {}
}

class _RefCollector extends Visitor {
  _RefCollector(this._refs);

  final Set<String> _refs;

  @override
  void visitReference<T>(RefOr<T> ref) {
    if (ref.ref != null) {
      _refs.add(ref.ref!);
    }
  }
}

Iterable<String> collectRefs(OpenApi root) {
  final refs = <String>{};
  final collector = _RefCollector(refs);
  SpecWalker(collector).walkRoot(root);
  return refs;
}

// Would be nice if Dart had a generic way to do this, without needing to
// teach the walker about all the types.
class SpecWalker {
  SpecWalker(this.visitor);

  final Visitor visitor;

  void walkRoot(OpenApi root) {
    visitor.visitRoot(root);
    for (final path in root.paths.paths.values) {
      walkPathItem(path);
    }
  }

  void walkPathItem(PathItem pathItem) {
    visitor.visitPathItem(pathItem);
    // for (final parameter in pathItem.parameters) {
    //   _parameter(parameter);
    // }
    for (final operation in pathItem.operations.values) {
      _operation(operation);
    }
  }

  void _operation(Operation operation) {
    visitor.visitOperation(operation);
    for (final response in operation.responses.responses.values) {
      _ref(response);
    }
    for (final parameter in operation.parameters) {
      _ref(parameter);
    }
    _maybeRef(operation.requestBody);
  }

  void _parameter(Parameter parameter) {
    visitor.visitParameter(parameter);
    _maybeRef(parameter.type);
  }

  void _response(Response response) {
    visitor.visitResponse(response);
    final content = response.content;
    if (content != null) {
      for (final mediaType in content.values) {
        _mediaType(mediaType);
      }
    }
  }

  void _maybeRef<T>(RefOr<T>? ref) {
    if (ref != null) {
      _ref(ref);
    }
  }

  void _ref<T>(RefOr<T> ref) {
    visitor.visitReference(ref);
    final object = ref.object;
    if (object == null) {
      return;
    }
    if (object is SchemaBase) {
      walkSchema(object);
    } else if (object is RequestBody) {
      _requestBody(object);
    } else if (object is Parameter) {
      _parameter(object);
    } else if (object is Response) {
      _response(object);
    } else {
      throw UnimplementedError('Unknown ref type: ${object.runtimeType}');
    }
  }

  void _mediaType(MediaType mediaType) {
    // visitor.visitMediaType(mediaType);
    _ref(mediaType.schema);
  }

  void _requestBody(RequestBody requestBody) {
    visitor.visitRequestBody(requestBody);
    for (final mediaType in requestBody.content.values) {
      _mediaType(mediaType);
    }
  }

  void walkSchema(SchemaBase schema) {
    visitor.visitSchema(schema);
    if (schema is Schema) {
      for (final property in schema.properties.values) {
        _maybeRef(property);
      }
      _maybeRef(schema.items);
      _maybeRef(schema.additionalProperties);
    } else if (schema is SchemaAllOf) {
      for (final ref in schema.schemas) {
        _ref(ref);
      }
    } else if (schema is SchemaAnyOf) {
      for (final ref in schema.schemas) {
        _ref(ref);
      }
    } else if (schema is SchemaOneOf) {
      for (final ref in schema.schemas) {
        _ref(ref);
      }
    } else {
      throw UnimplementedError('walkSchema: ${schema.runtimeType}');
    }
  }
}
