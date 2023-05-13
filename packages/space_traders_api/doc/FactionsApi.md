# openapi.api.FactionsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *https://api.spacetraders.io/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getFaction**](FactionsApi.md#getfaction) | **GET** /factions/{factionSymbol} | Get Faction
[**getFactions**](FactionsApi.md#getfactions) | **GET** /factions | List Factions


# **getFaction**
> GetFaction200Response getFaction(factionSymbol)

Get Faction

View the details of a faction.

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
final factionSymbol = factionSymbol_example; // String | The faction symbol

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
 **factionSymbol** | **String**| The faction symbol | [default to 'CGR']

### Return type

[**GetFaction200Response**](GetFaction200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFactions**
> GetFactions200Response getFactions(page, limit)

List Factions

List all discovered factions in the game.

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
final page = 56; // int | What entry offset to request
final limit = 56; // int | How many entries to return per page

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
 **page** | **int**| What entry offset to request | [optional] 
 **limit** | **int**| How many entries to return per page | [optional] 

### Return type

[**GetFactions200Response**](GetFactions200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

