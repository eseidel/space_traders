# space_traders_api.model.Ship

## Load the model package
```dart
import 'package:space_traders_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | **String** | The globally unique identifier of the ship in the following format: `[AGENT_SYMBOL]-[HEX_ID]` | 
**registration** | [**ShipRegistration**](ShipRegistration.md) |  | 
**nav** | [**ShipNav**](ShipNav.md) |  | 
**crew** | [**ShipCrew**](ShipCrew.md) |  | 
**frame** | [**ShipFrame**](ShipFrame.md) |  | 
**reactor** | [**ShipReactor**](ShipReactor.md) |  | 
**engine** | [**ShipEngine**](ShipEngine.md) |  | 
**modules** | [**List<ShipModule>**](ShipModule.md) | Modules installed in this ship. | [default to const []]
**mounts** | [**List<ShipMount>**](ShipMount.md) | Mounts installed in this ship. | [default to const []]
**cargo** | [**ShipCargo**](ShipCargo.md) |  | 
**fuel** | [**ShipFuel**](ShipFuel.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


