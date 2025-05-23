import 'package:spacetraders/model/faction_symbol.dart';

class RegisterRequest {
  RegisterRequest({required this.symbol, required this.faction});

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      symbol: json['symbol'] as String,
      faction: FactionSymbol.fromJson(json['faction'] as String),
    );
  }

  final String symbol;
  final FactionSymbol faction;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol, 'faction': faction.toJson()};
  }
}
