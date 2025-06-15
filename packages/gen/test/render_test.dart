import 'dart:convert';
import 'dart:io' as io;
import 'dart:mirrors';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:space_gen/src/logger.dart';
import 'package:space_gen/src/render.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _EmptyClass {}

class _Exists extends Matcher {
  const _Exists();

  @override
  bool matches(dynamic file, Map<dynamic, dynamic> matchState) {
    if (file is File) {
      return file.existsSync();
    }
    if (file is Directory) {
      return file.existsSync();
    }
    return false;
  }

  @override
  Description describe(Description description) => description.add('exists');
}

const exists = _Exists();

class _HasFiles extends CustomMatcher {
  _HasFiles(List<String> files)
    : super('has files', 'files', unorderedEquals(files));

  @override
  Object? featureValueOf(dynamic actual) {
    return (actual as Directory)
        .listSync()
        .whereType<File>()
        .map((e) => e.path.split('/').last)
        .toList();
  }
}

Matcher hasFiles(List<String> files) => _HasFiles(files);

void main() {
  group('loadAndRenderSpec', () {
    const localFs = LocalFileSystem();
    // https://github.com/dart-lang/test/issues/110
    final templatesUri = (reflectClass(_EmptyClass).owner! as LibraryMirror).uri
        .resolve('../lib/templates');
    final templateDir = localFs.directory(templatesUri.path);

    io.ProcessResult runProcess(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
    }) {
      return io.ProcessResult(0, 0, '', '');
    }

    Future<void> renderToDirectory({
      required Map<String, dynamic> spec,
      Directory? outDir,
      Logger? logger,
    }) async {
      final out = outDir ?? MemoryFileSystem.test().directory('spacetraders');
      final fs = out.fileSystem;
      final specFile = fs.file('spec.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(spec));
      await runWithLogger(
        logger ?? _MockLogger(),
        () => loadAndRenderSpec(
          specUri: Uri.file(specFile.path),
          packageName: out.path.split('/').last,
          outDir: out,
          templateDir: templateDir,
          runProcess: runProcess,
        ),
      );
    }

    test('deletes existing output directory', () async {
      final fs = MemoryFileSystem.test();
      final out = fs.directory('spacetraders');
      final spec = {
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
      final spuriousFile = out.childFile('foo.txt')
        ..createSync(recursive: true);
      expect(spuriousFile.existsSync(), isTrue);
      final logger = _MockLogger();
      await renderToDirectory(spec: spec, outDir: out, logger: logger);
      expect(spuriousFile.existsSync(), isFalse);
      expect(out.childFile('lib/api.dart'), exists);
      expect(out.childFile('lib/api_client.dart'), exists);
    });

    test('empty spec throws format exception', () async {
      await expectLater(
        () => renderToDirectory(spec: {}),
        throwsA(isA<FormatException>()),
      );
    });

    test('smoke test with simple spec', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
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
      final out = fs.directory('spacetraders');
      await renderToDirectory(spec: spec, outDir: out);
      expect(out, exists);
      expect(out.childFile('foo.txt'), isNot(exists));
      expect(
        out.childDirectory('lib'),
        hasFiles([
          'api.dart',
          'api_exception.dart',
          'api_client.dart',
          'model_helpers.dart',
        ]),
      );
    });

    test('with real endpoints', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users/{name}': {
            'get': {
              'operationId': 'get-user',
              'summary': 'Get User',
              'description': 'Fetch a user by name.',
              'parameters': [
                {
                  'schema': {'type': 'string'},
                  'in': 'path',
                  'name': 'name',
                  'required': true,
                  'description': 'The name of the user to fetch.',
                },
              ],
              'responses': {
                '200': {
                  'description': 'Default Response',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'data': {r'$ref': '#/components/schemas/Account'},
                        },
                        'required': ['data'],
                      },
                    },
                  },
                },
              },
            },
          },
        },
        'components': {
          'schemas': {
            'Account': {
              'type': 'object',
              'properties': {
                'role': {
                  'type': 'string',
                  'enum': ['admin', 'user'],
                  'description': 'The role of the account.',
                },
                'id': {'type': 'string'},
                'email': {'type': 'string', 'nullable': true},
              },
              'required': ['role', 'id'],
            },
          },
        },
      };
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(out.existsSync(), isTrue);
      expect(out.childFile('lib/api.dart'), exists);
      expect(out.childFile('lib/api_client.dart'), exists);
      expect(out.childFile('lib/api/default_api.dart'), exists);
      expect(out.childFile('lib/model/get_user200_response.dart'), exists);
      expect(out.childFile('lib/model/account.dart'), exists);
      expect(out.childFile('lib/model/account_role.dart'), exists);
    });

    test('with request body', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/my/ships/{shipSymbol}/purchase': {
            'post': {
              'operationId': 'purchase-cargo',
              'summary': 'Purchase Cargo',
              'tags': ['Fleet'],
              'description': 'Purchase cargo from a market.',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'symbol': {
                          'type': 'string',
                          'description': 'The symbol of the good to purchase.',
                        },
                        'units': {
                          'type': 'integer',
                          'minimum': 1,
                          'description':
                              'The number of units of the good to purchase.',
                        },
                      },
                      'required': ['symbol', 'units'],
                      'title': 'Purchase Cargo Request',
                    },
                  },
                },
                'required': true,
              },
              'parameters': [
                {
                  'schema': {'type': 'string'},
                  'in': 'path',
                  'name': 'shipSymbol',
                  'required': true,
                  'description': 'The symbol of the ship.',
                },
              ],
              'responses': {
                '201': {
                  'description': 'Purchased goods successfully.',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'data': {
                            'type': 'object',
                            'properties': {
                              'cargo': {
                                'type': 'object',
                                'properties': {
                                  'units': {
                                    'type': 'integer',
                                    'description': 'The number of units.',
                                  },
                                },
                              },
                            },
                            'required': ['cargo'],
                          },
                        },
                        'required': ['data'],
                        'title': 'Purchase Cargo 201 Response',
                        'description': 'Purchased goods successfully.',
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };
      final out = fs.directory('spacetraders');

      File outFile(String path) => out.childFile(path);
      File apiFile(String path) =>
          out.childDirectory('lib/api').childFile(path);

      await renderToDirectory(spec: spec, outDir: out);
      expect(out.existsSync(), isTrue);
      expect(outFile('lib/api.dart'), exists);
      expect(outFile('lib/api_client.dart'), exists);
      expect(apiFile('fleet_api.dart'), exists);
      expect(
        out.childDirectory('lib/model'),
        hasFiles([
          'purchase_cargo201_response.dart',
          'purchase_cargo201_response_data.dart',
          'purchase_cargo201_response_data_cargo.dart',
          'purchase_cargo_request.dart',
        ]),
      );
    });

    test('with newtype', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'operationId': 'get-user',
              'summary': 'Get User',
              'description': 'Fetch a user by name.',
              'parameters': [
                {
                  'schema': {'type': 'string'},
                  'in': 'query',
                  'name': 'id',
                  'required': true,
                  'description': 'The role of the user to fetch.',
                },
              ],
              'responses': {
                '200': {
                  'description': 'Default Response',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'user': {r'$ref': '#/components/schemas/User'},
                          'multiplier': {
                            r'$ref': '#/components/schemas/Multiplier',
                          },
                        },
                        'required': ['user', 'multiplier'],
                      },
                    },
                  },
                },
              },
            },
          },
        },
        'components': {
          'schemas': {
            'User': {'type': 'string'},
            'Multiplier': {'type': 'number'},
          },
        },
      };
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(out.childFile('lib/model/user.dart'), exists);
      expect(out.childFile('lib/model/multiplier.dart'), exists);
    });

    test('with default enum value', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'operationId': 'get-user',
              'summary': 'Get User',
              'description': 'Fetch a user by name.',
              'parameters': [
                {
                  'schema': {'type': 'string'},
                  'in': 'query',
                  'name': 'id',
                  'required': true,
                  'description': 'The role of the user to fetch.',
                },
              ],
              'responses': {
                '200': {
                  'description': 'Default Response',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'user': {r'$ref': '#/components/schemas/User'},
                        },
                        'required': ['user'],
                      },
                    },
                  },
                },
              },
            },
          },
        },
        'components': {
          'schemas': {
            'User': {
              'type': 'string',
              'enum': ['admin', 'user'],
              // Special handling is needed when an enum is default.
              'default': 'user',
            },
          },
        },
      };
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(out.childFile('lib/model/get_user200_response.dart'), exists);
      expect(out.childFile('lib/model/user.dart'), exists);
    });

    test('with additionalProperties', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'operationId': 'get-user',
              'summary': 'Get User',
              'description': 'Fetch a user by name.',
              'responses': {
                '200': {
                  'description': 'Default Response',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        // Makes this into a Map<String, String>
                        'additionalProperties': {'type': 'string'},
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(out.childFile('lib/model/get_user200_response.dart'), exists);
    });

    test('with inner types', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/my/factions': {
            'get': {
              'operationId': 'get-my-factions',
              'summary': 'Get My Factions',
              'description':
                  'Retrieve factions with which the agent has reputation.',
              'responses': {
                '200': {
                  'description': 'Default Response',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'data': {
                            'type': 'array',
                            'items': {
                              'type': 'object',
                              'properties': {
                                'symbol': {'type': 'string'},
                                'reputation': {'type': 'integer'},
                              },
                              'required': ['symbol', 'reputation'],
                            },
                          },
                        },
                        'required': ['data'],
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(
        out.childDirectory('lib/model'),
        hasFiles([
          'get_my_factions200_response.dart',
          'get_my_factions200_response_data_inner.dart',
        ]),
      );
    });

    test('with request body ref', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/my/ships/{shipSymbol}/purchase': {
            'post': {
              'operationId': 'purchase-cargo',
              'requestBody': {
                r'$ref': '#/components/requestBodies/PurchaseCargoRequest',
              },
              'responses': {
                '201': {'description': 'Purchased goods successfully.'},
              },
            },
          },
        },
        'components': {
          'requestBodies': {
            'PurchaseCargoRequest': {
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'symbol': {'type': 'string'},
                      'units': {'type': 'integer'},
                    },
                    'required': ['symbol', 'units'],
                  },
                },
              },
              'required': true,
            },
          },
        },
      };
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(
        out.childFile('lib/model/purchase_cargo_request.dart'),
        isNot(exists),
      );
      expect(out.childFile('lib/api/default_api.dart'), exists);
    });

    test('with boolean and unknown type', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'operationId': 'get-user',
              'responses': {
                '200': {
                  'description': 'Default Response',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'foo': {'type': 'boolean', 'default': true},
                          'bar': {
                            // No type is unknown and renders as dynamic.
                            'description': 'A description',
                          },
                        },
                        'required': ['foo'],
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(out.childDirectory('lib/api'), hasFiles(['default_api.dart']));
    });

    test('with datetime', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/users': {
            'get': {
              'operationId': 'get-user',
              'summary': 'Get User',
              'description': 'Fetch a user by name.',
              'responses': {
                '200': {
                  'description': 'Default Response',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'foo': {'type': 'string', 'format': 'date-time'},
                          'bar': {'type': 'string', 'format': 'date-time'},
                        },
                        // Bar is a nullable datetime, foo is non-nullable.
                        'required': ['foo'],
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(
        out.childDirectory('lib/model'),
        hasFiles(['get_user200_response.dart']),
      );
    });

    test('with array', () async {
      final fs = MemoryFileSystem.test();
      final spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Space Traders API', 'version': '1.0.0'},
        'servers': [
          {'url': 'https://api.spacetraders.io/v2'},
        ],
        'paths': {
          '/my/ships': {
            'get': {
              'operationId': 'get-my-ships',
              'responses': {
                '200': {
                  'description': 'Default Response',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'foo': {
                            'type': 'array',
                            'items': {'type': 'string'},
                          },
                          'bar': {
                            'type': 'array',
                            'items': {'type': 'number'},
                          },
                          'baz': {
                            'type': 'array',
                            'items': {'type': 'integer'},
                          },
                          'qux': {
                            'type': 'array',
                            'items': {'type': 'boolean'},
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(out.childFile('lib/api/default_api.dart'), exists);
      expect(
        out.childDirectory('lib/model'),
        hasFiles(['get_my_ships200_response.dart']),
      );
    });

    test('in=cookie not supported', () async {
      Map<String, dynamic> withIn(String sendIn) {
        return {
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
                    'schema': {'type': 'string'},
                    'in': sendIn,
                  },
                ],
                'responses': {
                  '200': {'description': 'OK'},
                },
              },
            },
          },
        };
      }

      await expectLater(renderToDirectory(spec: withIn('query')), completes);
      await expectLater(
        renderToDirectory(spec: withIn('cookie')),
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.toString(),
            'message',
            contains('Cookie parameters are not yet supported'),
          ),
        ),
      );
      await expectLater(renderToDirectory(spec: withIn('header')), completes);
    });

    test('responses without content are ignored', () async {
      final spec = {
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
      };
      final fs = MemoryFileSystem.test();
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(out.childFile('lib/api/default_api.dart'), exists);
      expect(out.childDirectory('lib/model'), isNot(exists));
    });

    test(
      'render the first content type even if application/json is missing',
      () async {
        final spec = {
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
                      // Note lack of application/json
                      'application/xml': {
                        'schema': {
                          'type': 'object',
                          'properties': {
                            'foo': {'type': 'string'},
                          },
                          'required': ['foo'],
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        };
        final fs = MemoryFileSystem.test();
        final out = fs.directory('spacetraders');

        await renderToDirectory(spec: spec, outDir: out);
        expect(out.childFile('lib/api/default_api.dart'), exists);
        expect(
          out.childDirectory('lib/model'),
          hasFiles(['users200_response.dart']),
        );
      },
    );

    test('allOf renders', () async {
      final spec = {
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
                      'schema': {
                        'allOf': [
                          {r'$ref': '#/components/schemas/User'},
                          {
                            'type': 'object',
                            'properties': {
                              'id': {'type': 'number'},
                            },
                          },
                        ],
                      },
                    },
                  },
                },
              },
            },
          },
        },
        'components': {
          'schemas': {
            'User': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'age': {'type': 'number'},
              },
              'required': ['name', 'age'],
            },
          },
        },
      };
      final fs = MemoryFileSystem.test();
      final out = fs.directory('spacetraders');

      await renderToDirectory(spec: spec, outDir: out);
      expect(out.childFile('lib/api/default_api.dart'), exists);
      expect(
        out.childDirectory('lib/model'),
        hasFiles(['users200_response.dart']),
      );
    });
  });
}
