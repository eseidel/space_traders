import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('Counts<T>', () {
    final counts = Counts<String>();
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
  });
}
