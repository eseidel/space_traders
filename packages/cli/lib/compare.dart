import 'package:cli/logger.dart';
import 'package:json_diff/json_diff.dart';

/// Compare two objects via json encoding.
bool jsonMatches<T extends Object>(T actual, T expected) {
  final differ = JsonDiffer.fromJson(actual, expected);
  final diff = differ.diff();
  if (diff.hasNothing) {
    return true;
  }
  logger.info('$T differs from expected: $diff');
  return false;
}
