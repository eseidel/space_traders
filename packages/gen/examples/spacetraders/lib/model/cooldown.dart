class Cooldown {
  Cooldown({
    required this.shipSymbol,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.expiration,
  });

  factory Cooldown.fromJson(Map<String, dynamic> json) {
    return Cooldown(
      shipSymbol: json['shipSymbol'] as String,
      totalSeconds: json['totalSeconds'] as int,
      remainingSeconds: json['remainingSeconds'] as int,
      expiration: DateTime.parse(json['expiration'] as String),
    );
  }

  final String shipSymbol;
  final int totalSeconds;
  final int remainingSeconds;
  final DateTime expiration;

  Map<String, dynamic> toJson() {
    return {
      'shipSymbol': shipSymbol,
      'totalSeconds': totalSeconds,
      'remainingSeconds': remainingSeconds,
      'expiration': expiration.toIso8601String(),
    };
  }
}
