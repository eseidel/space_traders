import 'package:cli/cache/jump_cache.dart';
import 'package:test/test.dart';

void main() {
  test('JumpCache sub-path', () async {
    final jumpCache = JumpCache()..addJumpPlan(JumpPlan(['A', 'B', 'C', 'D']));
    final ad = jumpCache.lookupJumpPlan(fromSystem: 'A', toSystem: 'D');
    expect(ad!.route, ['A', 'B', 'C', 'D']);
    final da = jumpCache.lookupJumpPlan(fromSystem: 'D', toSystem: 'A');
    expect(da!.route, ['D', 'C', 'B', 'A']);
    final bc = jumpCache.lookupJumpPlan(fromSystem: 'B', toSystem: 'C');
    expect(bc!.route, ['B', 'C']);
    final cb = jumpCache.lookupJumpPlan(fromSystem: 'C', toSystem: 'B');
    expect(cb!.route, ['C', 'B']);
  });
}
