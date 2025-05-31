import 'package:openapi/model_helpers.dart';

class JumpGate {
  JumpGate({required this.symbol, this.connections = const []});

  factory JumpGate.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return JumpGate(
      symbol: json['symbol'] as String,
      connections: (json['connections'] as List).cast<String>(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static JumpGate? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return JumpGate.fromJson(json);
  }

  String symbol;
  List<String> connections;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol, 'connections': connections};
  }

  @override
  int get hashCode => Object.hash(symbol, connections);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JumpGate &&
        symbol == other.symbol &&
        listsEqual(connections, other.connections);
  }
}
