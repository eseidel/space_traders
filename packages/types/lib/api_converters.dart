import 'package:json_annotation/json_annotation.dart';
import 'package:types/types.dart';

// OpenApi fromJson is nullable, which confuses JsonSerializable.
/// Makes OpenApi's `ShipType` enum work with JsonSerializable.
class ShipTypeConverter implements JsonConverter<ShipType, String> {
  /// Used to annotate [ShipType] properties of JsonSerializable classes.
  const ShipTypeConverter();

  @override
  ShipType fromJson(String json) => ShipType.fromJson(json);

  @override
  String toJson(ShipType object) => object.toJson();
}

// OpenApi fromJson is nullable, which confuses JsonSerializable.
/// Makes OpenApi's `TradeSymbol` enum work with JsonSerializable.
class TradeSymbolConverter implements JsonConverter<TradeSymbol, String> {
  /// Used to annotate [TradeSymbol] properties of JsonSerializable classes.
  const TradeSymbolConverter();

  @override
  TradeSymbol fromJson(String json) => TradeSymbol.fromJson(json);

  @override
  String toJson(TradeSymbol object) => object.toJson();
}
