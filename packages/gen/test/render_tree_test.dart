import 'package:space_gen/src/render_tree.dart';
import 'package:space_gen/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('equalsIgnoringName', () {
    test('RenderObject', () {
      const a = RenderObject(
        snakeName: 'a',
        pointer: JsonPointer.empty(),
        properties: <String, RenderSchema>{},
        additionalProperties: null,
        required: [],
      );
      expect(a.equalsIgnoringName(a), isTrue);

      const b = RenderObject(
        snakeName: 'b',
        pointer: JsonPointer.empty(),
        properties: <String, RenderSchema>{},
        additionalProperties: null,
        required: [],
      );
      expect(a.equalsIgnoringName(b), isTrue);

      const c = RenderObject(
        snakeName: 'a',
        pointer: JsonPointer.empty(),
        properties: <String, RenderSchema>{
          'a': RenderUnknown(snakeName: 'a', pointer: JsonPointer.empty()),
        },
        additionalProperties: null,
        required: [],
      );
      expect(a.equalsIgnoringName(c), isFalse);
    });
  });
}
