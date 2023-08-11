/// {@template query}
/// A query to be executed on the database.
/// {@endtemplate}
class Query {
  /// {@macro query}
  const Query(this.fmtString, {this.substitutionValues});

  /// The formatted string for the query.
  final String fmtString;

  /// The substitution values for the query.
  final Map<String, dynamic>? substitutionValues;
}
