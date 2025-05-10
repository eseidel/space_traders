# openapi.api.FactionsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *https://api.spacetraders.io/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getFaction**](FactionsApi.md#getfaction) | **GET** /factions/{factionSymbol} | Faction details
[**getFactions**](FactionsApi.md#getfactions) | **GET** /factions | List factions
[**getMyFactions**](FactionsApi.md#getmyfactions) | **GET** /my/factions | Get My Factions


# **getFaction**
> GetFaction200Response getFaction(factionSymbol)

Faction details

View the details of a faction.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AccountToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AccountToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AccountToken').setAccessToken(yourTokenGeneratorFunction);
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FactionsApi();
final factionSymbol = COSMIC; // String | The faction symbol

try {
    final result = api_instance.getFaction(factionSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FactionsApi->getFaction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **factionSymbol** | **String**| The faction symbol | 

### Return type

[**GetFaction200Response**](GetFaction200Response.md)

### Authorization

[AccountToken](../README.md#AccountToken), [AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFactions**
> GetFactions200Response getFactions(page, limit)

List factions

Return a paginated list of all the factions in the game.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FactionsApi();
final page = 1; // int | What entry offset to request
final limit = 10; // int | How many entries to return per page

try {
    final result = api_instance.getFactions(page, limit);
    print(result);
} catch (e) {
    print('Exception when calling FactionsApi->getFactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**| What entry offset to request | [optional] [default to 1]
 **limit** | **int**| How many entries to return per page | [optional] [default to 10]

### Return type

[**GetFactions200Response**](GetFactions200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyFactions**
> GetMyFactions200Response getMyFactions(page, limit)

Get My Factions

Retrieve factions with which the agent has reputation.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AccountToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AccountToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AccountToken').setAccessToken(yourTokenGeneratorFunction);
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FactionsApi();
final page = 1; // int | What entry offset to request
final limit = 10; // int | How many entries to return per page

try {
    final result = api_instance.getMyFactions(page, limit);
    print(result);
} catch (e) {
    print('Exception when calling FactionsApi->getMyFactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**| What entry offset to request | [optional] [default to 1]
 **limit** | **int**| How many entries to return per page | [optional] [default to 10]

### Return type

[**GetMyFactions200Response**](GetMyFactions200Response.md)

### Authorization

[AccountToken](../README.md#AccountToken), [AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

