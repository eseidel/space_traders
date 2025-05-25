import 'package:openapi/api_helpers.dart';
import 'package:openapi/model/contract_terms.dart';
import 'package:openapi/model/contract_type.dart';

class Contract {
  Contract({
    required this.id,
    required this.factionSymbol,
    required this.type,
    required this.terms,
    required this.expiration,
    this.accepted = false,
    this.fulfilled = false,
    this.deadlineToAccept,
  });

  factory Contract.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Contract(
      id: json['id'] as String,
      factionSymbol: json['factionSymbol'] as String,
      type: ContractType.fromJson(json['type'] as String),
      terms: ContractTerms.fromJson(json['terms'] as Map<String, dynamic>),
      accepted: json['accepted'] as bool,
      fulfilled: json['fulfilled'] as bool,
      expiration: DateTime.parse(json['expiration'] as String),
      deadlineToAccept: maybeParseDateTime(json['deadlineToAccept'] as String?),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Contract? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Contract.fromJson(json);
  }

  String id;
  String factionSymbol;
  ContractType type;
  ContractTerms terms;
  bool accepted;
  bool fulfilled;
  DateTime expiration;
  DateTime? deadlineToAccept;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'factionSymbol': factionSymbol,
      'type': type.toJson(),
      'terms': terms.toJson(),
      'accepted': accepted,
      'fulfilled': fulfilled,
      'expiration': expiration.toIso8601String(),
      'deadlineToAccept': deadlineToAccept?.toIso8601String(),
    };
  }

  @override
  int get hashCode => Object.hash(
    id,
    factionSymbol,
    type,
    terms,
    accepted,
    fulfilled,
    expiration,
    deadlineToAccept,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contract &&
        id == other.id &&
        factionSymbol == other.factionSymbol &&
        type == other.type &&
        terms == other.terms &&
        accepted == other.accepted &&
        fulfilled == other.fulfilled &&
        expiration == other.expiration &&
        deadlineToAccept == other.deadlineToAccept;
  }
}
