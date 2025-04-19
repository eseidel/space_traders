import 'package:json_annotation/json_annotation.dart';
import 'package:types/types.dart';

part 'get_deals_nearby_response.g.dart';

// OpenApi fromJson is nullable, which confuses JsonSerializable.
class ShipTypeConverter implements JsonConverter<ShipType, String> {
  const ShipTypeConverter();

  @override
  ShipType fromJson(String json) => ShipType.fromJson(json)!;

  @override
  String toJson(ShipType object) => object.toJson();
}

@JsonSerializable()
class DealsNearbyResponse {
  DealsNearbyResponse({
    required this.deals,
    required this.shipType,
    required this.shipSpec,
    required this.startSymbol,
    required this.credits,
    required this.extraSellOpps,
    required this.tradeSymbolCount,
  });

  factory DealsNearbyResponse.fromJson(Map<String, dynamic> json) =>
      _$DealsNearbyResponseFromJson(json);

  final List<NearbyDeal> deals;
  @ShipTypeConverter()
  final ShipType shipType;
  final ShipSpec shipSpec;
  final WaypointSymbol startSymbol;
  final int credits;
  final List<SellOpp> extraSellOpps;
  final int tradeSymbolCount;

  Map<String, dynamic> toJson() => _$DealsNearbyResponseToJson(this);
}

@JsonSerializable()
class NearbyDeal {
  NearbyDeal({required this.costed, required this.inProgress});

  factory NearbyDeal.fromJson(Map<String, dynamic> json) =>
      _$NearbyDealFromJson(json);

  final CostedDeal costed;
  final bool inProgress;

  Deal get deal => costed.deal;

  Map<String, dynamic> toJson() => _$NearbyDealToJson(this);
}
