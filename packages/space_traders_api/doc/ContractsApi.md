# openapi.api.ContractsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *https://api.spacetraders.io/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptContract**](ContractsApi.md#acceptcontract) | **POST** /my/contracts/{contractId}/accept | Accept Contract
[**deliverContract**](ContractsApi.md#delivercontract) | **POST** /my/contracts/{contractId}/deliver | Deliver Contract
[**fulfillContract**](ContractsApi.md#fulfillcontract) | **POST** /my/contracts/{contractId}/fulfill | Fulfill Contract
[**getContract**](ContractsApi.md#getcontract) | **GET** /my/contracts/{contractId} | Get Contract
[**getContracts**](ContractsApi.md#getcontracts) | **GET** /my/contracts | List Contracts


# **acceptContract**
> AcceptContract200Response acceptContract(contractId)

Accept Contract

Accept a contract.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContractsApi();
final contractId = contractId_example; // String | 

try {
    final result = api_instance.acceptContract(contractId);
    print(result);
} catch (e) {
    print('Exception when calling ContractsApi->acceptContract: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **contractId** | **String**|  | 

### Return type

[**AcceptContract200Response**](AcceptContract200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deliverContract**
> DeliverContract200Response deliverContract(contractId, deliverContractRequest)

Deliver Contract

Deliver cargo on a given contract.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContractsApi();
final contractId = contractId_example; // String | The ID of the contract
final deliverContractRequest = DeliverContractRequest(); // DeliverContractRequest | 

try {
    final result = api_instance.deliverContract(contractId, deliverContractRequest);
    print(result);
} catch (e) {
    print('Exception when calling ContractsApi->deliverContract: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **contractId** | **String**| The ID of the contract | 
 **deliverContractRequest** | [**DeliverContractRequest**](DeliverContractRequest.md)|  | [optional] 

### Return type

[**DeliverContract200Response**](DeliverContract200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **fulfillContract**
> FulfillContract200Response fulfillContract(contractId)

Fulfill Contract

Fulfill a contract

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContractsApi();
final contractId = contractId_example; // String | The ID of the contract

try {
    final result = api_instance.fulfillContract(contractId);
    print(result);
} catch (e) {
    print('Exception when calling ContractsApi->fulfillContract: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **contractId** | **String**| The ID of the contract | 

### Return type

[**FulfillContract200Response**](FulfillContract200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getContract**
> GetContract200Response getContract(contractId)

Get Contract

Get the details of a contract by ID.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContractsApi();
final contractId = contractId_example; // String | The contract ID

try {
    final result = api_instance.getContract(contractId);
    print(result);
} catch (e) {
    print('Exception when calling ContractsApi->getContract: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **contractId** | **String**| The contract ID | 

### Return type

[**GetContract200Response**](GetContract200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getContracts**
> GetContracts200Response getContracts(page, limit)

List Contracts

List all of your contracts.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContractsApi();
final page = 56; // int | What entry offset to request
final limit = 56; // int | How many entries to return per page

try {
    final result = api_instance.getContracts(page, limit);
    print(result);
} catch (e) {
    print('Exception when calling ContractsApi->getContracts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**| What entry offset to request | [optional] 
 **limit** | **int**| How many entries to return per page | [optional] 

### Return type

[**GetContracts200Response**](GetContracts200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

