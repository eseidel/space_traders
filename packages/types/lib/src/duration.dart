String _rounded(int whole, int part, int units, String suffix) {
  var absWhole = whole.abs();
  final partial = part / units;
  final sign = whole.sign;
  if (partial >= 0.5) {
    absWhole += 1;
  }
  return '${sign * absWhole}$suffix';
}

/// Create an approximate string for the given [duration].
String approximateDuration(Duration duration) {
  final d = duration; // Save some typing.
  if (d.inDays.abs() >= 365) {
    return '${(d.inDays / 365).round()}y';
  } else if (d.inDays.abs() >= 7) {
    return '${(d.inDays / 7).round()}w';
  } else if (d.inDays.abs() > 0) {
    final absDays = d.inDays.abs();
    final absHours = d.inHours.abs() - (absDays * 24);
    return _rounded(d.inDays, absHours, 24, 'd');
  } else if (d.inHours.abs() > 0) {
    final absHours = d.inHours.abs();
    final absMinutes = d.inMinutes.abs() - (absHours * 60);
    return _rounded(d.inHours, absMinutes, 60, 'h');
  } else if (d.inMinutes.abs() > 0) {
    final absMinutes = d.inMinutes.abs();
    final absSeconds = d.inSeconds.abs() - (absMinutes * 60);
    return _rounded(d.inMinutes, absSeconds, 60, 'm');
  } else if (d.inSeconds.abs() > 0) {
    final absSeconds = d.inSeconds.abs();
    final absMilliseconds = d.inMilliseconds.abs() - (absSeconds * 1000);
    return _rounded(d.inSeconds, absMilliseconds, 1000, 's');
  } else {
    return '${d.inMilliseconds}ms';
  }
}
