class Meta {
  Meta({required this.total, this.page = 1, this.limit = 10});

  factory Meta.fromJson(Map<String, dynamic> json) {
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

  final int total;
  final int page;
  final int limit;

  Map<String, dynamic> toJson() {
    return {'total': total, 'page': page, 'limit': limit};
  }

  @override
  int get hashCode => Object.hash(total, page, limit);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Meta &&
        total == other.total &&
        page == other.page &&
        limit == other.limit;
  }
}
