DateTime? maybeParseDateTime(String? value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value);
}
