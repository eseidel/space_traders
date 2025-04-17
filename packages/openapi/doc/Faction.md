# openapi.model.Faction

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**symbol** | [**FactionSymbol**](FactionSymbol.md) |  | 
**name** | **String** | Name of the faction. | 
**description** | **String** | Description of the faction. | 
**headquarters** | **String** | The waypoint in which the faction's HQ is located in. | [optional] 
**traits** | [**List<FactionTrait>**](FactionTrait.md) | List of traits that define this faction. | [default to const []]
**isRecruiting** | **bool** | Whether or not the faction is currently recruiting new agents. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


