import 'package:space_gen/src/spec.dart';
import 'package:test/test.dart';

void main() {
  group('Spec', () {
    Spec parseTestSpec(Map<String, dynamic> json) {
      return parseSpec(
        json,
        ParseContext.initial(Uri.parse('file:///foo.json')),
      );
    }

    test('parse', () {
      final specJson = {
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {'summary': 'Get user'},
          },
        },
      };
      final spec = parseTestSpec(specJson);
      expect(spec.serverUrl, Uri.parse('https://api.spacetraders.io/v2'));
      expect(spec.endpoints.first.path, '/users');
    });

    test('parse with invalid enum', () {
      final specJson = {
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {'summary': 'Get user'},
          },
        },
        'components': {
          'schemas': {
            'NumberEnum': {
              // This is valid according to the spec, but we don't support it.
              'type': 'number',
              'enum': [1, 2, 3],
            },
          },
        },
      };
      expect(() => parseTestSpec(specJson), throwsA(isA<UnimplementedError>()));
    });

    test('equals', () {
      final jsonOne = {
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {'summary': 'Get user'},
            'parameters': [
              {'name': 'foo', 'in': 'query', 'required': true},
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
        'components': {
          'schemas': {
            'Foo': {'type': 'object'},
          },
        },
      };
      final jsonTwo = {
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {'summary': 'Get user'},
          },
        },
      };
      final specOne = parseTestSpec(jsonOne);
      final specTwo = parseTestSpec(jsonOne);
      final specThree = parseTestSpec(jsonTwo);
      expect(specOne, specTwo);
      expect(specOne, isNot(specThree));
      expect(specOne.hashCode, specTwo.hashCode);
      expect(specOne.hashCode, isNot(specThree.hashCode));
    });

    test('anyOf nullable hack', () {
      final specJson = {
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {'summary': 'Get user'},
          },
        },
        'components': {
          'schemas': {
            'User': {
              'anyOf': [
                {'type': 'boolean'},
                {'type': 'null'},
              ],
            },
          },
        },
      };
      final spec = parseTestSpec(specJson);
      expect(spec.components.schemas['User']!.type, SchemaType.boolean);
    });

    test('anyOf array hack', () {
      final specJson = {
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {'summary': 'Get user'},
          },
        },
        'components': {
          'schemas': {
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
          },
        },
      };
      final spec = parseTestSpec(specJson);
      final schema = spec.components.schemas['User'];
      expect(schema!.type, SchemaType.array);
      expect(schema.items!.ref, '#/components/schemas/Value');
    });
  });

  group('RefOr', () {
    test('equality', () {
      const bodyOne = RequestBody(
        pointer: '#/components/requestBodies/Foo',
        isRequired: true,
        schema: SchemaRef.ref('#/components/schemas/Foo'),
      );
      const bodyTwo = RequestBody(
        pointer: '#/components/requestBodies/Foo',
        isRequired: true,
        schema: SchemaRef.ref('#/components/schemas/Foo'),
      );
      const refOrOne = RefOr.object(bodyOne);
      const refOrTwo = RefOr.object(bodyTwo);
      const refOrThree = RefOr.object(
        RequestBody(
          pointer: '#/components/requestBodies/Bar',
          isRequired: true,
          schema: SchemaRef.ref('#/components/schemas/Bar'),
        ),
      );
      expect(refOrOne, refOrTwo);
      expect(refOrOne, isNot(refOrThree));
      expect(refOrOne.hashCode, refOrTwo.hashCode);
      expect(refOrOne.hashCode, isNot(refOrThree.hashCode));
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
