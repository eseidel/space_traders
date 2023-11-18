# openapi.model.RefuelShipRequest

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**units** | **int** | The amount of fuel to fill in the ship's tanks. When not specified, the ship will be refueled to its maximum fuel capacity. If the amount specified is greater than the ship's remaining capacity, the ship will only be refueled to its maximum fuel capacity. The amount specified is not in market units but in ship fuel units. | [optional] 
**fromCargo** | **bool** | Wether to use the FUEL thats in your cargo or not. Default: false | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


