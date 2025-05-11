# openapi.model.ShipyardShip

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**type** | [**ShipType**](ShipType.md) |  | 
**name** | **String** | Name of the ship. | 
**description** | **String** | Description of the ship. | 
**activity** | [**ActivityLevel**](ActivityLevel.md) |  | [optional] 
**supply** | [**SupplyLevel**](SupplyLevel.md) |  | 
**purchasePrice** | **int** | The purchase price of the ship. | 
**frame** | [**ShipFrame**](ShipFrame.md) |  | 
**reactor** | [**ShipReactor**](ShipReactor.md) |  | 
**engine** | [**ShipEngine**](ShipEngine.md) |  | 
**modules** | [**List<ShipModule>**](ShipModule.md) | Modules installed in this ship. | [default to const []]
**mounts** | [**List<ShipMount>**](ShipMount.md) | Mounts installed in this ship. | [default to const []]
**crew** | [**ShipyardShipCrew**](ShipyardShipCrew.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


