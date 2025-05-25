class Cooldown {
  Cooldown({
    required this.shipSymbol,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.expiration,
  });

  factory Cooldown.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Cooldown(
      shipSymbol: json['shipSymbol'] as String,
      totalSeconds: json['totalSeconds'] as int,
      remainingSeconds: json['remainingSeconds'] as int,
      expiration: DateTime.parse(json['expiration'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Cooldown? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Cooldown.fromJson(json);
  }

  String shipSymbol;
  int totalSeconds;
  int remainingSeconds;
  DateTime expiration;

  Map<String, dynamic> toJson() {
    return {
      'shipSymbol': shipSymbol,
      'totalSeconds': totalSeconds,
      'remainingSeconds': remainingSeconds,
      'expiration': expiration.toIso8601String(),
    };
  }
}
