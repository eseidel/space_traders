# openapi.model.Contract

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**factionSymbol** | **String** | The symbol of the faction that this contract is for. | 
**type** | **String** |  | 
**terms** | [**ContractTerms**](ContractTerms.md) |  | 
**accepted** | **bool** | Whether the contract has been accepted by the agent | [default to false]
**fulfilled** | **bool** | Whether the contract has been fulfilled | [default to false]
**expiration** | [**DateTime**](DateTime.md) | The time at which the contract expires | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


