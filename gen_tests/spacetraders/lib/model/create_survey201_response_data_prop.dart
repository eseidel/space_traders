import 'package:meta/meta.dart';
import 'package:spacetraders/model/cooldown.dart';
import 'package:spacetraders/model/survey.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class CreateSurvey201ResponseDataProp {
  const CreateSurvey201ResponseDataProp({
    required this.cooldown,
    List<Survey>? surveys,
  }) : surveys = surveys ?? const <Survey>[];

  factory CreateSurvey201ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return CreateSurvey201ResponseDataProp(
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      surveys: (json['surveys'] as List)
          .map<Survey>((e) => Survey.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static CreateSurvey201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return CreateSurvey201ResponseDataProp.fromJson(json);
  }

  final Cooldown cooldown;
  final List<Survey> surveys;

  Map<String, dynamic> toJson() {
    return {
      'cooldown': cooldown.toJson(),
      'surveys': surveys.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hashAll([cooldown, surveys]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateSurvey201ResponseDataProp &&
        cooldown == other.cooldown &&
        listsEqual(surveys, other.surveys);
  }
}
