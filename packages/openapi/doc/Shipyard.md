# openapi.model.Shipyard

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | **String** | The symbol of the shipyard. The symbol is the same as the waypoint where the shipyard is located. | 
**shipTypes** | [**List<ShipyardShipTypesInner>**](ShipyardShipTypesInner.md) | The list of ship types available for purchase at this shipyard. | [default to const []]
**transactions** | [**List<ShipyardTransaction>**](ShipyardTransaction.md) | The list of recent transactions at this shipyard. | [optional] [default to const []]
**ships** | [**List<ShipyardShip>**](ShipyardShip.md) | The ships that are currently available for purchase at the shipyard. | [optional] [default to const []]
**modificationsFee** | **int** | The fee to modify a ship at this shipyard. This includes installing or removing modules and mounts on a ship. In the case of mounts, the fee is a flat rate per mount. In the case of modules, the fee is per slot the module occupies. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


