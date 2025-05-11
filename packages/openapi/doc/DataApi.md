# openapi.api.DataApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *https://api.spacetraders.io/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getSupplyChain**](DataApi.md#getsupplychain) | **GET** /market/supply-chain | Describes trade relationships
[**websocketDepartureEvents**](DataApi.md#websocketdepartureevents) | **GET** /my/socket.io | Subscribe to events


# **getSupplyChain**
> GetSupplyChain200Response getSupplyChain()

Describes trade relationships

Describes which import and exports map to each other.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DataApi();

try {
    final result = api_instance.getSupplyChain();
    print(result);
} catch (e) {
    print('Exception when calling DataApi->getSupplyChain: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**GetSupplyChain200Response**](GetSupplyChain200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **websocketDepartureEvents**
> websocketDepartureEvents()

Subscribe to events

Subscribe to departure events for a system.            ## WebSocket Events            The following events are available:            - `systems.{systemSymbol}.departure`: A ship has departed from the system.            ## Subscribe using a message with the following format:            ```json           {             \"action\": \"subscribe\",             \"systemSymbol\": \"{systemSymbol}\"           }           ```            ## Unsubscribe using a message with the following format:            ```json           {             \"action\": \"unsubscribe\",             \"systemSymbol\": \"{systemSymbol}\"           }           ```

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DataApi();

try {
    api_instance.websocketDepartureEvents();
} catch (e) {
    print('Exception when calling DataApi->websocketDepartureEvents: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

