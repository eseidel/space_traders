import 'package:openapi/model/cooldown.dart';
import 'package:openapi/model/survey.dart';

class CreateSurvey201ResponseData {
  CreateSurvey201ResponseData({required this.cooldown, required this.surveys});

  factory CreateSurvey201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return CreateSurvey201ResponseData(
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      surveys:
          (json['surveys'] as List<dynamic>)
              .map<Survey>((e) => Survey.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static CreateSurvey201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return CreateSurvey201ResponseData.fromJson(json);
  }

  Cooldown cooldown;
  List<Survey> surveys;

  Map<String, dynamic> toJson() {
    return {
      'cooldown': cooldown.toJson(),
      'surveys': surveys.map((e) => e.toJson()).toList(),
    };
  }
}
