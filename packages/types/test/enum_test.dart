import 'package:test/test.dart';
import 'package:types/enum.dart';

enum _Enum with EnumIndexOrdering<_Enum> { one, two, three }

void main() {
  test('EnumIndexOrdering', () {
    expect(_Enum.one < _Enum.two, isTrue);
    expect(_Enum.one <= _Enum.two, isTrue);
    expect(_Enum.three >= _Enum.three, isTrue);
    expect(_Enum.three >= _Enum.two, isTrue);
    expect(_Enum.three > _Enum.two, isTrue);
    final list = [_Enum.three, _Enum.one, _Enum.two]..sort();
    expect(list, [_Enum.one, _Enum.two, _Enum.three]);
  });
}
