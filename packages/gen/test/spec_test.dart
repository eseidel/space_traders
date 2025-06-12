import 'package:space_gen/src/spec.dart';
import 'package:test/test.dart';

void main() {
  group('RefOr', () {
    test('equality', () {
      final schema = Schema(
        pointer: '#/components/schemas/Foo',
        snakeName: 'foo',
        description: 'Foo',
        type: SchemaType.object,
        properties: const {},
        required: const [],
        items: null,
        enumValues: const [],
        format: '',
        additionalProperties: null,
        defaultValue: null,
        example: null,
        useNewType: false,
      );

      final bodyOne = RequestBody(
        pointer: '#/components/requestBodies/Foo',
        description: 'Foo',
        content: {'application/json': MediaType(schema: schema)},
        isRequired: true,
      );
      final bodyTwo = RequestBody(
        pointer: '#/components/requestBodies/Foo',
        description: 'Foo',
        content: {'application/json': MediaType(schema: schema)},
        isRequired: true,
      );
      final refOrOne = RefOr.object(bodyOne);
      final refOrTwo = RefOr.object(bodyTwo);
      final refOrThree = RefOr.object(
        RequestBody(
          pointer: '#/components/requestBodies/Bar',
          description: 'Bar',
          content: {'application/json': MediaType(schema: schema)},
          isRequired: true,
        ),
      );
      expect(refOrOne, refOrTwo);
      expect(refOrOne, isNot(refOrThree));
      expect(refOrOne.hashCode, refOrTwo.hashCode);
      expect(refOrOne.hashCode, isNot(refOrThree.hashCode));
    });
  });
}
