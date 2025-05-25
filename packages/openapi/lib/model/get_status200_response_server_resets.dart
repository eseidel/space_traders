class GetStatus200ResponseServerResets {
  GetStatus200ResponseServerResets({
    required this.next,
    required this.frequency,
  });

  factory GetStatus200ResponseServerResets.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetStatus200ResponseServerResets(
      next: json['next'] as String,
      frequency: json['frequency'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseServerResets? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseServerResets.fromJson(json);
  }

  String next;
  String frequency;

  Map<String, dynamic> toJson() {
    return {'next': next, 'frequency': frequency};
  }
}
