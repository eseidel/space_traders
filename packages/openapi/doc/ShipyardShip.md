# openapi.model.ShipyardShip

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**type** | [**ShipType**](ShipType.md) |  | 
**name** | **String** |  | 
**description** | **String** |  | 
**supply** | [**SupplyLevel**](SupplyLevel.md) |  | 
**activity** | [**ActivityLevel**](ActivityLevel.md) |  | [optional] 
**purchasePrice** | **int** |  | 
**frame** | [**ShipFrame**](ShipFrame.md) |  | 
**reactor** | [**ShipReactor**](ShipReactor.md) |  | 
**engine** | [**ShipEngine**](ShipEngine.md) |  | 
**modules** | [**List<ShipModule>**](ShipModule.md) |  | [default to const []]
**mounts** | [**List<ShipMount>**](ShipMount.md) |  | [default to const []]
**crew** | [**ShipyardShipCrew**](ShipyardShipCrew.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


