# openapi.model.Waypoint

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | **String** | Symbol fo the waypoint. | 
**type** | [**WaypointType**](WaypointType.md) |  | 
**systemSymbol** | **String** | The symbol of the system this waypoint belongs to. | 
**x** | **int** | Relative position of the waypoint on the system's x axis. This is not an absolute position in the universe. | 
**y** | **int** | Relative position of the waypoint on the system's y axis. This is not an absolute position in the universe. | 
**orbitals** | [**List<WaypointOrbital>**](WaypointOrbital.md) | Waypoints that orbit this waypoint. | [default to const []]
**orbits** | **String** | The symbol of the parent waypoint, if this waypoint is in orbit around another waypoint. Otherwise this value is undefined. | [optional] 
**faction** | [**WaypointFaction**](WaypointFaction.md) |  | [optional] 
**traits** | [**List<WaypointTrait>**](WaypointTrait.md) | The traits of the waypoint. | [default to const []]
**chart** | [**Chart**](Chart.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

