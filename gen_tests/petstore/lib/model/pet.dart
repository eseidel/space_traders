import 'package:meta/meta.dart';
import 'package:petstore/model/category.dart';
import 'package:petstore/model/pet_status_prop.dart';
import 'package:petstore/model/tag.dart';
import 'package:petstore/model_helpers.dart';

@immutable
class Pet {
  const Pet({
    required this.name,
    this.id,
    this.category,
    this.photoUrls = const [],
    List<Tag>? tags,
    this.status,
  }) : tags = tags ?? const [];

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as int?,
      name: json['name'] as String,
      category: Category.maybeFromJson(
        json['category'] as Map<String, dynamic>?,
      ),
      photoUrls: (json['photoUrls'] as List).cast<String>(),
      tags: (json['tags'] as List?)
          ?.map<Tag>((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: PetStatusProp.maybeFromJson(json['status'] as String?),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Pet? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Pet.fromJson(json);
  }

  final int? id;
  final String name;
  final Category? category;
  final List<String> photoUrls;
  final List<Tag>? tags;
  final PetStatusProp? status;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category?.toJson(),
      'photoUrls': photoUrls,
      'tags': tags?.map((e) => e.toJson()).toList(),
      'status': status?.toJson(),
    };
  }

  @override
  int get hashCode =>
      Object.hashAll([id, name, category, photoUrls, tags, status]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pet &&
        id == other.id &&
        name == other.name &&
        category == other.category &&
        listsEqual(photoUrls, other.photoUrls) &&
        listsEqual(tags, other.tags) &&
        status == other.status;
  }
}
