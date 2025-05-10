# openapi.model.System

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**constellation** | **String** | The constellation that the system is part of. | [optional] 
**symbol** | **String** | The symbol of the system. | 
**sectorSymbol** | **String** | The symbol of the sector. | 
**type** | [**SystemType**](SystemType.md) |  | 
**x** | **int** | Relative position of the system in the sector in the x axis. | 
**y** | **int** | Relative position of the system in the sector in the y axis. | 
**waypoints** | [**List<SystemWaypoint>**](SystemWaypoint.md) | Waypoints in this system. | [default to const []]
**factions** | [**List<SystemFaction>**](SystemFaction.md) | Factions that control this system. | [default to const []]
**name** | **String** | The name of the system. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


