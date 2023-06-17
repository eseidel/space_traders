# space_traders_api.model.System

## Load the model package
```dart
import 'package:space_traders_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | **String** | The symbol of the system. | 
**sectorSymbol** | **String** | The symbol of the sector. | 
**type** | [**SystemType**](SystemType.md) |  | 
**x** | **int** | Position in the universe in the x axis. | 
**y** | **int** | Position in the universe in the y axis. | 
**waypoints** | [**List<SystemWaypoint>**](SystemWaypoint.md) | Waypoints in this system. | [default to const []]
**factions** | [**List<SystemFaction>**](SystemFaction.md) | Factions that control this system. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


