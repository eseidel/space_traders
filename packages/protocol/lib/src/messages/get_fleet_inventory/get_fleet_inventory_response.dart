import 'package:json_annotation/json_annotation.dart';
import 'package:types/api_converters.dart';
import 'package:types/types.dart';

part 'get_fleet_inventory_response.g.dart';

@JsonSerializable()
class ItemValue {
  ItemValue({
    required this.tradeSymbol,
    required this.count,
    required this.medianPrice,
  });

  factory ItemValue.fromJson(Map<String, dynamic> json) =>
      _$ItemValueFromJson(json);

  @TradeSymbolConverter()
  final TradeSymbol tradeSymbol;
  final int count;
  final int? medianPrice;

  Map<String, dynamic> toJson() => _$ItemValueToJson(this);
}

@JsonSerializable()
class GetFleetInventoryResponse {
  GetFleetInventoryResponse({required this.items});

  factory GetFleetInventoryResponse.fromJson(Map<String, dynamic> json) =>
      _$GetFleetInventoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetFleetInventoryResponseToJson(this);

  Set<TradeSymbol> get missingPrices {
    return items
        .where((item) => item.medianPrice == null)
        .map((item) => item.tradeSymbol)
        .toSet();
  }

  int get totalValue {
    return items.fold(0, (total, item) {
      final price = item.medianPrice;
      if (price == null) {
        return total;
      }
      return total + (item.count * price);
    });
  }

  final List<ItemValue> items;
}
