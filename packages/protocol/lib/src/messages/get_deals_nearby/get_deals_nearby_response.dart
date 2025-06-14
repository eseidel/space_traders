import 'package:json_annotation/json_annotation.dart';
import 'package:protocol/src/models/get_request.dart';
import 'package:types/api_converters.dart';
import 'package:types/types.dart';

part 'get_deals_nearby_response.g.dart';

class GetDealsNearbyRequest implements GetRequest {
  GetDealsNearbyRequest({
    required this.shipType,
    required this.limit,
    required this.credits,
    required this.start,
  });
  factory GetDealsNearbyRequest.fromQueryParameters(
    Map<String, String?> parameters,
  ) {
    final maybeShipType = parameters['shipType'];
    final maybeLimit = parameters['limit'];
    final maybeCredits = parameters['credits'];
    final maybeStart = parameters['start'];
    return GetDealsNearbyRequest(
      shipType: maybeShipType != null ? ShipType.fromJson(maybeShipType) : null,
      limit: maybeLimit != null ? int.tryParse(maybeLimit) : null,
      credits: maybeCredits != null ? int.tryParse(maybeCredits) : null,
      start: maybeStart != null ? WaypointSymbol.fromString(maybeStart) : null,
    );
  }

  static ShipType defaultShipType = ShipType.COMMAND_FRIGATE;
  final ShipType? shipType;

  static const int defaultLimit = 10;
  final int? credits;

  static const int defaultCredits = 1000000;
  final int? limit;

  final WaypointSymbol? start;

  @override
  Map<String, String?> toQueryParameters() => {
    if (shipType != null) 'shipType': shipType?.toJson(),
    if (limit != null) 'limit': limit.toString(),
    if (credits != null) 'credits': credits.toString(),
    if (start != null) 'start': start?.toJson(),
  };
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

  /// The ShipType used for costing the deals.
  @ShipTypeConverter()
  final ShipType shipType;

  /// The ShipSpec used for costing the deals.
  final ShipSpec shipSpec;

  /// The start location for costing the deals.
  final WaypointSymbol startSymbol;

  /// The maximum credits available for the deals.
  final int credits;

  /// The extra sell opportunities available for the deals, including contracts.
  final List<SellOpp> extraSellOpps;

  final int tradeSymbolCount;

  Map<String, dynamic> toJson() => _$DealsNearbyResponseToJson(this);
}

@JsonSerializable()
class NearbyDeal {
  NearbyDeal({required this.costed, required this.inProgress});

  factory NearbyDeal.fromJson(Map<String, dynamic> json) =>
      _$NearbyDealFromJson(json);

  /// The costed deal.
  final CostedDeal costed;

  /// Whether we already have a ship attempting to execute this deal.
  final bool inProgress;

  Deal get deal => costed.deal;

  Map<String, dynamic> toJson() => _$NearbyDealToJson(this);
}
