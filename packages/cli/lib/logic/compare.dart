import 'dart:convert';

import 'package:cli/logger.dart';
import 'package:json_diff/json_diff.dart';

/// Compare two objects via json encoding.
bool jsonMatches<T extends Object>(T actual, T expected) {
  // Encode both objects to json to avoid cases where the objects are
  // different but the json is the same.
  final actualString = jsonEncode(actual);
  final expectedString = jsonEncode(expected);
  final differ = JsonDiffer(actualString, expectedString);
  final diff = differ.diff();
  if (diff.hasNothing) {
    return true;
  }
  logger.info('$T differs from expected: $diff');
  return false;
}
