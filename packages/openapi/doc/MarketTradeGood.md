# openapi.model.MarketTradeGood

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | [**TradeSymbol**](TradeSymbol.md) |  | 
**type** | **String** | The type of trade good (export, import, or exchange). | 
**tradeVolume** | **int** | This is the maximum number of units that can be purchased or sold at this market in a single trade for this good. Trade volume also gives an indication of price volatility. A market with a low trade volume will have large price swings, while high trade volume will be more resilient to price changes. | 
**supply** | [**SupplyLevel**](SupplyLevel.md) |  | 
**activity** | [**ActivityLevel**](ActivityLevel.md) |  | [optional] 
**purchasePrice** | **int** | The price at which this good can be purchased from the market. | 
**sellPrice** | **int** | The price at which this good can be sold to the market. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


