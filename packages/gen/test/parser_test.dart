import 'package:mocktail/mocktail.dart';
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/parser.dart';
import 'package:space_gen/src/spec.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('parser', () {
    OpenApi parseTestSpec(Map<String, dynamic> json) {
      return parseOpenApi(
        MapContext.initial(Uri.parse('file:///foo.json'), json),
      );
    }

    Map<String, SchemaBase> parseTestSchemas(Map<String, dynamic> schemasJson) {
      final specJson = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'summary': 'Get user',
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
        'components': {'schemas': schemasJson},
      };
      final spec = parseTestSpec(specJson);
      return spec.components.schemas;
    }

    test('parse', () {
      final specJson = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'summary': 'Get user',
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      };
      final logger = _MockLogger();
      final spec = runWithLogger(logger, () => parseTestSpec(specJson));
      expect(spec.serverUrl, Uri.parse('https://api.spacetraders.io/v2'));
      expect(spec.paths.keys.first, '/users');
    });

    test('parse with invalid enum', () {
      final json = {
        'NumberEnum': {
          // This is valid according to the spec, but we don't support it.
          'type': 'number',
          'enum': [1, 2, 3],
        },
      };
      final logger = _MockLogger();
      expect(
        () => runWithLogger(logger, () => parseTestSchemas(json)),
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            equals(
              'enumValues for type=SchemaType.number not supported in '
              'MapContext(/components/schemas/NumberEnum, '
              '{type: number, enum: [1, 2, 3]})',
            ),
          ),
        ),
      );
    });

    test('OpenApi equals', () {
      final jsonOne = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'summary': 'Get user',
              'parameters': [
                {
                  'name': 'foo',
                  'in': 'query',
                  'required': true,
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'object'},
                    },
                  },
                },
              },
            },
          },
        },
        'components': {
          'schemas': {
            'Foo': {'type': 'object'},
          },
        },
      };
      final jsonTwo = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'summary': 'Get user',
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      };
      final logger = _MockLogger();
      final specOne = runWithLogger(logger, () => parseTestSpec(jsonOne));
      final specTwo = runWithLogger(logger, () => parseTestSpec(jsonOne));
      final specThree = runWithLogger(logger, () => parseTestSpec(jsonTwo));
      expect(specOne, specTwo);
      expect(specOne, isNot(specThree));
      expect(specOne.hashCode, specTwo.hashCode);
      expect(specOne.hashCode, isNot(specThree.hashCode));
    });

    test('anyOf nullable hack', () {
      final json = {
        'User': {
          'anyOf': [
            {'type': 'boolean'},
            {'type': 'null'},
          ],
        },
      };
      final logger = _MockLogger();
      final schemas = runWithLogger(logger, () => parseTestSchemas(json));
      expect(schemas['User']!.type, SchemaType.boolean);
    });

    test('anyOf array hack', () {
      final json = {
        'User': {
          'anyOf': [
            {
              'type': 'array',
              'items': {r'$ref': '#/components/schemas/Value'},
            },
            {r'$ref': '#/components/schemas/Value'},
          ],
        },
        'Value': {'type': 'boolean'},
      };
      final logger = _MockLogger();
      final schemas = runWithLogger(logger, () => parseTestSchemas(json));
      final schema = schemas['User']! as Schema;
      expect(schema.type, SchemaType.array);
      expect(schema.items!.ref, '#/components/schemas/Value');
    });

    test('anyOf with one value', () {
      final json = {
        'User': {
          'anyOf': [
            {'type': 'boolean'},
          ],
        },
      };
      final logger = _MockLogger();
      final schemas = runWithLogger(logger, () => parseTestSchemas(json));
      expect(schemas['User']!.type, SchemaType.boolean);
    });

    test('anyOf parses as SchemaAnyOf', () {
      final json = {
        'User': {
          'anyOf': [
            {'type': 'boolean'},
            {'type': 'string'},
          ],
        },
      };
      final logger = _MockLogger();
      final schemas = runWithLogger(logger, () => parseTestSchemas(json));
      expect(schemas['User'], isA<SchemaAnyOf>());
    });

    test('allOf with one item', () {
      final json = {
        'User': {
          'allOf': [
            {'type': 'boolean'},
          ],
        },
      };
      final logger = _MockLogger();
      final schemas = runWithLogger(logger, () => parseTestSchemas(json));
      expect(schemas['User']!.type, SchemaType.boolean);
    });

    test('allOf with multiple items', () {
      final json = {
        'User': {
          'allOf': [
            {'type': 'boolean'},
            {'type': 'string'},
          ],
        },
      };
      final logger = _MockLogger();
      final schemas = runWithLogger(logger, () => parseTestSchemas(json));
      expect(schemas['User'], isA<SchemaAllOf>());
    });

    test('oneOf not supported', () {
      final json = {
        'User': {
          'oneOf': [
            {'type': 'boolean'},
          ],
        },
      };
      final logger = _MockLogger();
      final schemas = runWithLogger(logger, () => parseTestSchemas(json));
      expect(schemas['User'], isA<SchemaOneOf>());
    });

    test('components schemas as ref not supported', () {
      // Refs are generally fine.
      final json = {
        'User': {
          'type': 'object',
          'properties': {
            'value': {r'$ref': '#/components/schemas/Value'},
          },
        },
        'Value': {'type': 'boolean'},
      };
      final logger = _MockLogger();
      final schemas = runWithLogger(logger, () => parseTestSchemas(json));
      final schema = schemas['User']! as Schema;
      expect(schema.type, SchemaType.object);
      expect(schema.properties['value']!.ref, '#/components/schemas/Value');

      // Just not as a direct alias/redirect
      final json2 = {
        'User': {r'$ref': '#/components/schemas/Value'},
        'Value': {'type': 'boolean'},
      };
      expect(
        () => runWithLogger(logger, () => parseTestSchemas(json2)),
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            equals(
              r'$ref not supported in '
              'MapContext(/components/schemas/User, '
              r'{$ref: #/components/schemas/Value})',
            ),
          ),
        ),
      );
    });

    test('components not supported keys', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'summary': 'Get user',
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
        'components': {
          'headers': {
            'X-Foo': {'type': 'string', 'description': 'Foo'},
          },
        },
      };
      final logger = _MockLogger();
      expect(
        () => runWithLogger(logger, () => parseTestSpec(json)),
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            equals(
              'headers not supported in MapContext(/components, '
              '{headers: {X-Foo: {type: string, description: Foo}}})',
            ),
          ),
        ),
      );
    });

    test('parameter with schema and content', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'parameters': [
                {
                  'name': 'foo',
                  'in': 'query',
                  // Both schema and content are not allowed at the same time.
                  'schema': {'type': 'boolean'},
                  'content': {
                    'application/json': {
                      'schema': {'type': 'boolean'},
                    },
                  },
                },
              ],
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('schema and content'),
          ),
        ),
      );
    });

    test('parameter with no schema or content', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'parameters': [
                {'name': 'foo', 'in': 'query'},
              ],
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('schema or content'),
          ),
        ),
      );
    });

    test('content is not supported', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'summary': 'Get user',
              'parameters': [
                {
                  'name': 'foo',
                  'in': 'query',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'boolean'},
                    },
                  },
                },
              ],
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      };
      final logger = _MockLogger();
      expect(
        () => runWithLogger(logger, () => parseTestSpec(json)),
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            equals(
              "'content' not supported in "
              'MapContext(/paths//users/get/parameters/0, {name: foo, '
              'in: query, content: {application/json: '
              '{schema: {type: boolean}}}})',
            ),
          ),
        ),
      );
    });

    test('warn on version below 3.0.0', () {
      final json = {
        'openapi': '2.9.9',
        'info': {'title': 'Space Traders API', 'version': '1.0.0.a.b.c'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'summary': 'Get user',
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      };

      final logger = _MockLogger();
      final spec = runWithLogger(logger, () => parseTestSpec(json));
      verify(
        () => logger.warn(
          '2.9.9 < 3.0.0, the lowest known supported version. in /',
        ),
      ).called(1);
      expect(spec.version, Version.parse('2.9.9'));
      // Info.version is the version of the spec, not the version of the OpenAPI
      // schema used to generate it and can be an arbitrary string.
      expect(spec.info.version, '1.0.0.a.b.c');
    });

    test('wrong type for responses', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            // This should throw a FormatException for having an optional
            // key of the wrong type.
            'get': {'responses': true},
          },
        },
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals(
              "'responses' is not of type Map<String, dynamic>: true in /paths//users/get",
            ),
          ),
        ),
      );
    });

    test('empty paths', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {'': <String, dynamic>{}},
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals('Path cannot be empty in /paths/'),
          ),
        ),
      );
    });

    test('info is required', () {
      final json = {
        'openapi': '3.1.0',
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals('Key info is required in /'),
          ),
        ),
      );
    });
    test('servers is required', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals('Key servers is required in /'),
          ),
        ),
      );
    });

    test('path parameters must be strings', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'summary': 'Get user',
              'parameters': [
                {
                  'name': 'foo',
                  'in': 'path',
                  'schema': {'type': 'number'},
                },
              ],
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      };
      final logger = _MockLogger();
      expect(
        () => runWithLogger(logger, () => parseTestSpec(json)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals(
              'Path parameters must be strings or integers in '
              '/paths//users/get/parameters/0',
            ),
          ),
        ),
      );
    });

    test('path parameters must be required', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'summary': 'Get user',
              'parameters': [
                {
                  'name': 'foo',
                  'in': 'path',
                  'schema': {'type': 'string'},
                  // required is missing and defaults to false.
                },
              ],
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      };
      final logger = _MockLogger();
      expect(
        () => runWithLogger(logger, () => parseTestSpec(json)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals(
              'Path parameters must be required in /paths//users/get/parameters/0',
            ),
          ),
        ),
      );
    });

    test('multiple responses with content not supported', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'boolean'},
                    },
                  },
                },
                '201': {
                  'description': 'Created',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'string'},
                    },
                  },
                },
              },
            },
          },
        },
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            contains('Multiple responses with content not supported'),
          ),
        ),
      );
    });

    test('multiple responses with content ignores empty responses', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'boolean'},
                    },
                  },
                },
                '204': {
                  'description': 'No content',
                  'content': {
                    'application/json': {
                      // This doesn't error because schema is empty.
                      // This is a hack for Space Traders get-cooldown.
                      'schema': {'description': 'No content'},
                    },
                  },
                },
              },
            },
          },
        },
      };
      final spec = parseTestSpec(json);
      expect(
        spec.paths['/users'].operations[Method.get]!.responses[200]!.content,
        isNotNull,
      );
      expect(
        spec.paths['/users'].operations[Method.get]!.responses[204]!.content,
        isNotNull,
      );
    });

    test('only integers and default are supported as response codes', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'responses': {
                '200': {'description': 'OK'},
                'barf': {'description': 'Barf'},
              },
            },
          },
        },
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals(
              'Invalid response code: barf in /paths//users/get/responses',
            ),
          ),
        ),
      );
    });
    test('default response is not supported', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'responses': {
                'default': {'description': 'Default'},
                '201': {'description': 'Created'},
              },
            },
          },
        },
      };
      final logger = _MockLogger();
      final spec = runWithLogger(logger, () => parseTestSpec(json));
      expect(
        spec.paths['/users'].operations[Method.get]!.responses[200],
        isNull,
      );
    });

    test('responses are required', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {'responses': <String, dynamic>{}},
          },
        },
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals('Responses are required in /paths//users/get'),
          ),
        ),
      );
    });

    test('request body with empty content is not supported', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'post': {
              'summary': 'Post user',
              'responses': {
                '200': {'description': 'OK'},
              },
              'requestBody': {'content': <String, dynamic>{}},
            },
          },
        },
      };
      expect(
        () => parseTestSpec(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals('Empty content in /paths//users/post/requestBody/content'),
          ),
        ),
      );
    });

    // This is a hack to make petstore work enough for now.
    test('default to first media type if no application/json', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'post': {
              'summary': 'Post user',
              'responses': {
                '200': {'description': 'OK'},
              },
              'requestBody': {
                'content': {
                  'application/xml': {
                    'schema': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      };
      final logger = _MockLogger();
      final spec = runWithLogger(logger, () => parseTestSpec(json));
      expect(
        spec
            .paths['/users']
            .operations[Method.post]!
            .requestBody
            ?.object
            ?.content,
        isNotNull,
      );
      expect(
        spec
            .paths['/users']
            .operations[Method.post]!
            .requestBody
            ?.object
            ?.content
            .keys
            .first,
        'application/xml',
      );
    });

    test('parameters can be refs', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'parameters': [
                {r'$ref': '#/components/parameters/foo'},
              ],
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
        'components': {
          'parameters': {
            'foo': {
              'name': 'foo',
              'in': 'query',
              'schema': {'type': 'string'},
            },
          },
        },
      };
      final logger = _MockLogger();
      final spec = runWithLogger(logger, () => parseTestSpec(json));
      expect(spec.paths['/users'].operations[Method.get]!.parameters, [
        isA<RefOr<Parameter>>().having(
          (p) => p.ref,
          'ref',
          equals('#/components/parameters/foo'),
        ),
      ]);
    });

    test('ignores securitySchemes', () {
      final json = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
        'components': {
          'securitySchemes': {
            'foo': {'type': 'http'},
          },
        },
      };
      final logger = _MockLogger();
      runWithLogger(logger, () => parseTestSpec(json));
      verify(() => logger.warn('Ignoring securitySchemes.')).called(1);
    });
  });

  group('ParseContext', () {
    test('MapContext.childAsMap throws on missing child', () {
      final context = MapContext.initial(Uri.parse('file:///foo.json'), {
        'foo': {'bar': 'baz'},
      });
      expect(context.pointer, const JsonPointer([]));
      expect(context.childAsMap('foo'), isA<MapContext>());
      expect(
        () => context.childAsList('foo'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals("'foo' is not of type List<dynamic>: {bar: baz} in /"),
          ),
        ),
      );
      expect(
        () => context.childAsMap('bar'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            equals('Key not found: bar in /'),
          ),
        ),
      );
    });

    test('MapContext.childAsList throws on missing child', () {
      final context = MapContext.initial(Uri.parse('file:///foo.json'), {
        'foo': ['bar'],
      });
      expect(context.pointer, const JsonPointer([]));
      expect(context.childAsList('foo'), isA<ListContext>());
      expect(
        () => context.childAsMap('foo'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals("'foo' is not of type Map<String, dynamic>: [bar] in /"),
          ),
        ),
      );
      expect(
        () => context.childAsMap('bar'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            equals('Key not found: bar in /'),
          ),
        ),
      );
    });

    test('ListContext.indexAsMap throws on missing child', () {
      final context = ListContext(
        baseUrl: Uri.parse('file:///foo.json'),
        pointerParts: const ['root'],
        snakeNameStack: const [],
        refRegistry: RefRegistry(),
        isTopLevelComponent: false,
        json: [
          {'foo': 'bar'},
          'baz',
        ],
      );
      expect(context.pointer, const JsonPointer(['root']));
      expect(context.indexAsMap(0), isA<MapContext>());
      expect(
        () => context.indexAsMap(1),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            equals('Index 1 is not of type Map<String, dynamic>: baz in /root'),
          ),
        ),
      );
      expect(
        () => context.indexAsMap(2),
        throwsA(
          isA<RangeError>().having(
            (e) => e.message,
            'message',
            equals('Invalid value'),
          ),
        ),
      );
    });
  });

  group('JsonPointer', () {
    test('equality', () {
      const pointerOne = JsonPointer(['foo', 'bar']);
      const pointerTwo = JsonPointer(['foo', 'bar']);
      const pointerThree = JsonPointer(['foo', 'baz']);
      expect(pointerOne, pointerTwo);
      expect(pointerOne.hashCode, pointerTwo.hashCode);
      expect(pointerOne, isNot(pointerThree));
      expect(pointerOne.hashCode, isNot(pointerThree.hashCode));
    });
  });
}
