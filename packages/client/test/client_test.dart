import 'package:client/client.dart';
import 'package:test/test.dart';

void main() {
  group(BackendClient, () {
    test('can be instantiated', () {
      expect(BackendClient(hostedUri: Uri()), isNotNull);
    });
  });
}
