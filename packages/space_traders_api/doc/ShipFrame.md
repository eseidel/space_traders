# space_traders_api.model.ShipFrame

## Load the model package
```dart
import 'package:space_traders_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | **String** | Symbol of the frame. | 
**name** | **String** | Name of the frame. | 
**description** | **String** | Description of the frame. | 
**condition** | **int** | Condition is a range of 0 to 100 where 0 is completely worn out and 100 is brand new. | [optional] 
**moduleSlots** | **int** | The amount of slots that can be dedicated to modules installed in the ship. Each installed module take up a number of slots, and once there are no more slots, no new modules can be installed. | 
**mountingPoints** | **int** | The amount of slots that can be dedicated to mounts installed in the ship. Each installed mount takes up a number of points, and once there are no more points remaining, no new mounts can be installed. | 
**fuelCapacity** | **int** | The maximum amount of fuel that can be stored in this ship. When refueling, the ship will be refueled to this amount. | 
**requirements** | [**ShipRequirements**](ShipRequirements.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


