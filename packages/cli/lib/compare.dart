import 'dart:convert';

import 'package:cli/logger.dart';
import 'package:cli/third_party/compare.dart';

export 'third_party/compare.dart';

/// Compare two objects via json encoding.
bool jsonCompare<T>(T actual, T expected) {
  final diff = findDifferenceBetweenStrings(
    jsonEncode(actual),
    jsonEncode(expected),
  );
  if (diff != null) {
    logger.info('$T differs from expected: ${diff.which}');
    return false;
  }
  return true;
}

/// Returns true if the two lists of T match when converted to Json.
bool jsonListMatch<T>(
  List<T> actual,
  List<T> expected,
) {
  if (actual.length != expected.length) {
    logger.info(
      "$T list lengths don't match: "
      '${actual.length} != ${expected.length}',
    );
    return false;
  }

  for (var i = 0; i < actual.length; i++) {
    final diff = findDifferenceBetweenStrings(
      jsonEncode(actual[i]),
      jsonEncode(expected[i]),
    );
    if (diff != null) {
      logger.info('$T list differs at index $i: ${diff.which}');
      return false;
    }
  }
  return true;
}
