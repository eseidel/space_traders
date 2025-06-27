import 'package:meta/meta.dart';

@immutable
class GetStatus200ResponseLinksPropInner {
  const GetStatus200ResponseLinksPropInner({
    required this.name,
    required this.url,
  });

  factory GetStatus200ResponseLinksPropInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetStatus200ResponseLinksPropInner(
      name: json['name'] as String,
      url: Uri.parse(json['url'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseLinksPropInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseLinksPropInner.fromJson(json);
  }

  final String name;
  final Uri url;

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url.toString()};
  }

  @override
  int get hashCode => Object.hashAll([name, url]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetStatus200ResponseLinksPropInner &&
        name == other.name &&
        url == other.url;
  }
}
