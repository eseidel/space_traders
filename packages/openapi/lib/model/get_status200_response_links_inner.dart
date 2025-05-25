class GetStatus200ResponseLinksInner {
  GetStatus200ResponseLinksInner({required this.name, required this.url});

  factory GetStatus200ResponseLinksInner.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetStatus200ResponseLinksInner(
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseLinksInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseLinksInner.fromJson(json);
  }

  String name;
  String url;

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url};
  }
}
