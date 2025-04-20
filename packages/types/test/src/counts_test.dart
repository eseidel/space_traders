import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('RequestCounts', () {
    final counts = RequestCounts();
    expect(counts.total, 0);
    counts.record('/foo');
    expect(counts.total, 1);
    counts.record('/foo');
    expect(counts.total, 2);
    counts.record('/bar');
    expect(counts.total, 3);
    expect(counts.counts, {'/foo': 2, '/bar': 1});
    counts.reset();
    expect(counts.total, 0);
    expect(counts.counts, <String, int>{});

    final before = RequestCounts({'/foo': 2, '/bar': 1});
    final after = RequestCounts({'/foo': 3, '/bar': 1});
    final diff = after.diff(before);
    expect(diff.counts, {'/foo': 1});
  });

  test('captureTimeAndRequests', () async {
    final requestCounts = RequestCounts()..record('/before');
    final queryCounts = QueryCounts()..record('SELECT * FROM before_');
    final result = await captureTimeAndRequests(
      requestCounts,
      queryCounts,
      () async {
        requestCounts.record('/during');
        queryCounts.record('SELECT * FROM during_');
        return 42;
      },
      onComplete: (duration, requestCount, queryCounts) {
        expect(requestCount, 1);
        expect(queryCounts.total, 1);
        expect(queryCounts.counts, {'SELECT * FROM during_': 1});
      },
    );
    expect(result, 42);
  });
}
