import 'package:intl/intl.dart';

/// Format the given [credits] as a string.
// Possibly credits should be a different type from int?
String creditsString(int credits) {
  final creditsFormat = NumberFormat();
  return '${creditsFormat.format(credits)}c';
}
