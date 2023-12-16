# openapi.model.ScannedWaypoint

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | **String** | The symbol of the waypoint. | 
**type** | [**WaypointType**](WaypointType.md) |  | 
**systemSymbol** | **String** | The symbol of the system. | 
**x** | **int** | Position in the universe in the x axis. | 
**y** | **int** | Position in the universe in the y axis. | 
**orbitals** | [**List<WaypointOrbital>**](WaypointOrbital.md) | List of waypoints that orbit this waypoint. | [default to const []]
**faction** | [**WaypointFaction**](WaypointFaction.md) |  | [optional] 
**traits** | [**List<WaypointTrait>**](WaypointTrait.md) | The traits of the waypoint. | [default to const []]
**chart** | [**Chart**](Chart.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


