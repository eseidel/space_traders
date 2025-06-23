import 'package:meta/meta.dart';

@immutable
class Category {
  const Category({this.id, this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'] as int?, name: json['name'] as String?);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Category? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Category.fromJson(json);
  }

  final int? id;
  final String? name;

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  int get hashCode => Object.hashAll([id, name]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && id == other.id && name == other.name;
  }
}
