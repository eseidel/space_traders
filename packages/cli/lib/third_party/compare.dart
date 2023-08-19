// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Given single-character string, return the hex-escaped equivalent.
String _hexLiteral(String input) {
  final rune = input.runes.single;
  return r'\x' + rune.toRadixString(16).toUpperCase().padLeft(2, '0');
}

/// Returns [output] with all whitespace characters represented as their escape
/// sequences.
///
/// Backslash characters are escaped as `\\`
String escape(String output) {
  return output.replaceAll(r'\', r'\\').replaceAllMapped(_escapeRegExp,
      (match) {
    final mapped = _escapeMap[match[0]];
    if (mapped != null) return mapped;
    return _hexLiteral(match[0]!);
  });
}

/// A [RegExp] that matches whitespace characters that should be escaped.
final _escapeRegExp = RegExp(
  '[\\x00-\\x07\\x0E-\\x1F${_escapeMap.keys.map(_hexLiteral).join()}]',
);

/// A [Map] between whitespace characters and their escape sequences.
const _escapeMap = {
  '\n': r'\n',
  '\r': r'\r',
  '\f': r'\f',
  '\b': r'\b',
  '\t': r'\t',
  '\v': r'\v',
  '\x7F': r'\x7F', // delete
};

/// Returns a [Rejection] describing why [actual] does not match expected.
final class Rejection {
  /// Creates a new [Rejection] with the given [actual] and [which] values.
  Rejection({this.actual = const [], this.which});

  /// The actual value.
  final Iterable<String> actual;

  /// Description of how actual failed to match expected.
  final Iterable<String>? which;
}

/// The truncated beginning of [s] up to the [end] character.
String _leading(String s, int end) =>
    (end > 10) ? '... ${s.substring(end - 10, end)}' : s.substring(0, end);

/// The truncated remainder of [s] starting at the [start] character.
String _trailing(String s, int start) => (start + 10 > s.length)
    ? s.substring(start)
    : '${s.substring(start, start + 10)} ...';

/// Returns a [Rejection] describing why [actual] does not match [expected].
Rejection? findDifferenceBetweenStrings(
  String actual,
  String expected,
) {
  if (actual == expected) return null;
  final escapedActual = escape(actual);
  final escapedExpected = escape(expected);
  final minLength = math.min(escapedActual.length, escapedExpected.length);
  var i = 0;
  for (; i < minLength; i++) {
    if (escapedActual.codeUnitAt(i) != escapedExpected.codeUnitAt(i)) {
      break;
    }
  }
  if (i == minLength) {
    if (escapedExpected.length < escapedActual.length) {
      if (expected.isEmpty) {
        return Rejection(which: ['is not the empty string']);
      }
      return Rejection(
        which: [
          'is too long with unexpected trailing characters:',
          _trailing(escapedActual, i),
        ],
      );
    } else {
      if (actual.isEmpty) {
        return Rejection(
          actual: ['an empty string'],
          which: [
            'is missing all expected characters:',
            _trailing(escapedExpected, 0),
          ],
        );
      }
      return Rejection(
        which: [
          'is too short with missing trailing characters:',
          _trailing(escapedExpected, i),
        ],
      );
    }
  } else {
    final indentation = ' ' * (i > 10 ? 14 : i);
    return Rejection(
      which: [
        'differs at offset $i:',
        '${_leading(escapedExpected, i)}${_trailing(escapedExpected, i)}',
        '${_leading(escapedActual, i)}${_trailing(escapedActual, i)}',
        '$indentation^',
      ],
    );
  }
}
