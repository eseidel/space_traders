# space_traders_api.model.Contract

## Load the model package
```dart
import 'package:space_traders_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | ID of the contract. | 
**factionSymbol** | **String** | The symbol of the faction that this contract is for. | 
**type** | **String** | Type of contract. | 
**terms** | [**ContractTerms**](ContractTerms.md) |  | 
**accepted** | **bool** | Whether the contract has been accepted by the agent | [default to false]
**fulfilled** | **bool** | Whether the contract has been fulfilled | [default to false]
**expiration** | [**DateTime**](DateTime.md) | Deprecated in favor of deadlineToAccept | 
**deadlineToAccept** | [**DateTime**](DateTime.md) | The time at which the contract is no longer available to be accepted | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


