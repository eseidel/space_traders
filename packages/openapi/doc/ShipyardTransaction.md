# openapi.model.ShipyardTransaction

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**waypointSymbol** | **String** | The symbol of the waypoint. | 
**shipSymbol** | **String** | The symbol of the ship type (e.g. SHIP_MINING_DRONE) that was the subject of the transaction. Contrary to what the name implies, this is NOT the symbol of the ship that was purchased. | 
**shipType** | **String** | The symbol of the ship type (e.g. SHIP_MINING_DRONE) that was the subject of the transaction. | 
**price** | **int** | The price of the transaction. | 
**agentSymbol** | **String** | The symbol of the agent that made the transaction. | 
**timestamp** | [**DateTime**](DateTime.md) | The timestamp of the transaction. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


