# openapi.model.SystemWaypoint

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | **String** | The symbol of the waypoint. | 
**type** | [**WaypointType**](WaypointType.md) |  | 
**x** | **int** | Relative position of the waypoint on the system's x axis. This is not an absolute position in the universe. | 
**y** | **int** | Relative position of the waypoint on the system's y axis. This is not an absolute position in the universe. | 
**orbitals** | [**List<WaypointOrbital>**](WaypointOrbital.md) | Waypoints that orbit this waypoint. | [default to const []]
**orbits** | **String** | The symbol of the parent waypoint, if this waypoint is in orbit around another waypoint. Otherwise this value is undefined. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


