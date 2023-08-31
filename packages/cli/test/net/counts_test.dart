import 'package:cli/net/counts.dart';
import 'package:test/test.dart';

void main() {
  test('RequestCounts', () {
    final counts = RequestCounts();
    expect(counts.totalRequests, 0);
    counts.recordRequest('/foo');
    expect(counts.totalRequests, 1);
    counts.recordRequest('/foo');
    expect(counts.totalRequests, 2);
    counts.recordRequest('/bar');
    expect(counts.totalRequests, 3);
    expect(counts.counts, {'/foo': 2, '/bar': 1});
    counts.reset();
    expect(counts.totalRequests, 0);
    expect(counts.counts, <String, int>{});
  });
}
