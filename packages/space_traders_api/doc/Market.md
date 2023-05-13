# openapi.model.Market

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | **String** | The symbol of the market. The symbol is the same as the waypoint where the market is located. | 
**exports** | [**List<TradeGood>**](TradeGood.md) | The list of goods that are exported from this market. | [default to const []]
**imports** | [**List<TradeGood>**](TradeGood.md) | The list of goods that are sought as imports in this market. | [default to const []]
**exchange** | [**List<TradeGood>**](TradeGood.md) | The list of goods that are bought and sold between agents at this market. | [default to const []]
**transactions** | [**List<MarketTransaction>**](MarketTransaction.md) | The list of recent transactions at this market. Visible only when a ship is present at the market. | [optional] [default to const []]
**tradeGoods** | [**List<MarketTradeGood>**](MarketTradeGood.md) | The list of goods that are traded at this market. Visible only when a ship is present at the market. | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


