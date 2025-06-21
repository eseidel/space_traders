import 'package:meta/meta.dart';

@immutable
class Tag {
  const Tag({this.id, this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(id: json['id'] as int?, name: json['name'] as String?);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Tag? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Tag.fromJson(json);
  }

  final int? id;
  final String? name;

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  int get hashCode => Object.hash(id, name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && id == other.id && name == other.name;
  }
}
