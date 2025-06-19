    // test('foo', () async {
    //   final spec = {
    //     'openapi': '3.1.0',
    //     'info': {'title': 'Space Traders API', 'version': '1.0.0'},
    //     'servers': [
    //       {'url': 'https://api.spacetraders.io/v2'},
    //     ],
    //     'paths': {
    //       '/pet/findByStatus': {
    //         'get': {
    //           'operationId': 'findPetsByStatus',
    //           'responses': {
    //             '200': {
    //               'description': 'successful operation',
    //               'content': {
    //                 'application/json': {
    //                   'schema': {
    //                     'type': 'array',
    //                     'items': {r'$ref': '#/components/schemas/Pet'},
    //                   },
    //                 },
    //               },
    //             },
    //           },
    //         },
    //       },
    //     },
    //     'components': {
    //       'schemas': {
    //         'Pet': {
    //           'required': ['id', 'name'],
    //           'type': 'object',
    //           'properties': {
    //             'id': {'type': 'integer', 'format': 'int64', 'example': 10},
    //             'name': {'type': 'string', 'example': 'doggie'},
    //           },
    //         },
    //       },
    //     },
    //   };
    //   final fs = MemoryFileSystem.test();
    //   final out = fs.directory('spacetraders');

    //   await renderToDirectory(spec: spec, outDir: out);
    //   expect(out.childFile('lib/api/default_api.dart'), exists);
    //   expect(out.childDirectory('lib/model'), hasFiles(['pet.dart']));
    // });
