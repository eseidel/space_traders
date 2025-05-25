class Meta {
  Meta({required this.total, this.page = 1, this.limit = 10});

  factory Meta.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Meta(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Meta? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Meta.fromJson(json);
  }

  int total;
  int page;
  int limit;

  Map<String, dynamic> toJson() {
    return {'total': total, 'page': page, 'limit': limit};
  }
}
