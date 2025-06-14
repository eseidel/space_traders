class GetStatus200ResponseAnnouncementsInner {
  GetStatus200ResponseAnnouncementsInner({
    required this.title,
    required this.body,
  });

  factory GetStatus200ResponseAnnouncementsInner.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetStatus200ResponseAnnouncementsInner(
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseAnnouncementsInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseAnnouncementsInner.fromJson(json);
  }

  String title;
  String body;

  Map<String, dynamic> toJson() {
    return {'title': title, 'body': body};
  }

  @override
  int get hashCode => Object.hash(title, body);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetStatus200ResponseAnnouncementsInner &&
        title == other.title &&
        body == other.body;
  }
}
