import 'package:test/test.dart';
import 'package:types/src/credits.dart';

void main() {
  group('creditsString', () {
    test('formats positive numbers without sign', () {
      expect(creditsString(1000), equals('1,000c'));
      expect(creditsString(1000000), equals('1,000,000c'));
      expect(creditsString(0.5), equals('0.5c'));
    });

    test('formats negative numbers with - sign', () {
      expect(creditsString(-1000), equals('-1,000c'));
      expect(creditsString(-1000000), equals('-1,000,000c'));
      expect(creditsString(-0.5), equals('-0.5c'));
    });

    test('formats zero', () {
      expect(creditsString(0), equals('0c'));
    });
  });

  group('creditsChangeString', () {
    test('formats positive numbers with + sign', () {
      expect(creditsChangeString(1000), equals('+1,000c'));
      expect(creditsChangeString(1000000), equals('+1,000,000c'));
      expect(creditsChangeString(0.5), equals('+0.5c'));
    });

    test('formats negative numbers with - sign', () {
      expect(creditsChangeString(-1000), equals('-1,000c'));
      expect(creditsChangeString(-1000000), equals('-1,000,000c'));
      expect(creditsChangeString(-0.5), equals('-0.5c'));
    });

    test('formats zero without sign', () {
      expect(creditsChangeString(0), equals('0c'));
    });
  });
}
