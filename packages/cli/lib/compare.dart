import 'dart:convert';

import 'package:cli/logger.dart';
import 'package:cli/third_party/compare.dart';
import 'package:json_diff/json_diff.dart';

export 'third_party/compare.dart';

/// Compare two objects via json encoding.
bool jsonMatches<T extends Object>(T actual, T expected) {
  final differ = JsonDiffer(jsonEncode(actual), jsonEncode(expected));
  final diff = differ.diff();
  if (diff.hasNothing) {
    return true;
  }
  logger.info('$T differs from expected: $diff');
  return true;
}

/// Returns true if the two lists of T match when converted to Json.
bool jsonListMatches<T extends Object>(List<T> actual, List<T> expected) {
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
