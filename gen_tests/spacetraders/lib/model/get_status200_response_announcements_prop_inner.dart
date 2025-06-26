import 'package:meta/meta.dart';

@immutable
class GetStatus200ResponseAnnouncementsPropInner {
  const GetStatus200ResponseAnnouncementsPropInner({
    required this.title,
    required this.body,
  });

  factory GetStatus200ResponseAnnouncementsPropInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetStatus200ResponseAnnouncementsPropInner(
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseAnnouncementsPropInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseAnnouncementsPropInner.fromJson(json);
  }

  final String title;
  final String body;

  Map<String, dynamic> toJson() {
    return {'title': title, 'body': body};
  }

  @override
  int get hashCode => Object.hashAll([title, body]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetStatus200ResponseAnnouncementsPropInner &&
        title == other.title &&
        body == other.body;
  }
}
