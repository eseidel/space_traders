import 'package:cli/api.dart';
import 'package:cli/nav/jump_cache.dart';
import 'package:test/test.dart';

void main() {
  test('JumpCache sub-path', () async {
    final a = SystemSymbol.fromString('S-A');
    final b = SystemSymbol.fromString('S-B');
    final c = SystemSymbol.fromString('S-C');
    final d = SystemSymbol.fromString('S-D');

    final jumpCache = JumpCache()..addJumpPlan(JumpPlan([a, b, c, d]));
    final ad = jumpCache.lookupJumpPlan(fromSystem: a, toSystem: d);
    expect(ad!.route, [a, b, c, d]);
    final da = jumpCache.lookupJumpPlan(fromSystem: d, toSystem: a);
    expect(da!.route, [d, c, b, a]);
    final bc = jumpCache.lookupJumpPlan(fromSystem: b, toSystem: c);
    expect(bc!.route, [b, c]);
    final cb = jumpCache.lookupJumpPlan(fromSystem: c, toSystem: b);
    expect(cb!.route, [c, b]);
  });
}
