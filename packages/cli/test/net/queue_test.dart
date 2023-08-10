import 'package:cli/net/queue.dart';
import 'package:test/test.dart';

void main() {
  test('QueuedRequest roundtrip', () {
    final request = QueuedRequest.empty('http://example.com');
    final json = request.toJson();
    final request2 = QueuedRequest.fromJson(json);
    expect(request2.method, equals('GET'));
  });

  test('QueuedResponse roundtrip', () {
    final request = QueuedResponse(
      body: 'foo',
      headers: {
        'Content-Type': 'text/plain',
      },
      statusCode: 200,
    );
    final json = request.toJson();
    final request2 = QueuedResponse.fromJson(json);
    expect(request2.statusCode, equals(200));
  });
}
