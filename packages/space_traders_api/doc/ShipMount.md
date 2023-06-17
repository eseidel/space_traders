# space_traders_api.model.ShipMount

## Load the model package
```dart
import 'package:space_traders_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | **String** | Symbo of this mount. | 
**name** | **String** | Name of this mount. | 
**description** | **String** | Description of this mount. | [optional] 
**strength** | **int** | Mounts that have this value, such as mining lasers, denote how powerful this mount's capabilities are. | [optional] 
**deposits** | **List<String>** | Mounts that have this value denote what goods can be produced from using the mount. | [optional] [default to const []]
**requirements** | [**ShipRequirements**](ShipRequirements.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


