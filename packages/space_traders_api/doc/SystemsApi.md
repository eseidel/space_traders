# openapi.api.SystemsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *https://api.spacetraders.io/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getJumpGate**](SystemsApi.md#getjumpgate) | **GET** /systems/{systemSymbol}/waypoints/{waypointSymbol}/jump-gate | Get Jump Gate
[**getMarket**](SystemsApi.md#getmarket) | **GET** /systems/{systemSymbol}/waypoints/{waypointSymbol}/market | Get Market
[**getShipyard**](SystemsApi.md#getshipyard) | **GET** /systems/{systemSymbol}/waypoints/{waypointSymbol}/shipyard | Get Shipyard
[**getSystem**](SystemsApi.md#getsystem) | **GET** /systems/{systemSymbol} | Get System
[**getSystemWaypoints**](SystemsApi.md#getsystemwaypoints) | **GET** /systems/{systemSymbol}/waypoints | List Waypoints
[**getSystems**](SystemsApi.md#getsystems) | **GET** /systems | List Systems
[**getWaypoint**](SystemsApi.md#getwaypoint) | **GET** /systems/{systemSymbol}/waypoints/{waypointSymbol} | Get Waypoint


# **getJumpGate**
> GetJumpGate200Response getJumpGate(systemSymbol, waypointSymbol)

Get Jump Gate

Get jump gate details for a waypoint.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SystemsApi();
final systemSymbol = systemSymbol_example; // String | The system symbol
final waypointSymbol = waypointSymbol_example; // String | The waypoint symbol

try {
    final result = api_instance.getJumpGate(systemSymbol, waypointSymbol);
    print(result);
} catch (e) {
    print('Exception when calling SystemsApi->getJumpGate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **systemSymbol** | **String**| The system symbol | 
 **waypointSymbol** | **String**| The waypoint symbol | 

### Return type

[**GetJumpGate200Response**](GetJumpGate200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMarket**
> GetMarket200Response getMarket(systemSymbol, waypointSymbol)

Get Market

Retrieve imports, exports and exchange data from a marketplace. Imports can be sold, exports can be purchased, and exchange goods can be purchased or sold. Send a ship to the waypoint to access trade good prices and recent transactions.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SystemsApi();
final systemSymbol = systemSymbol_example; // String | The system symbol
final waypointSymbol = waypointSymbol_example; // String | The waypoint symbol

try {
    final result = api_instance.getMarket(systemSymbol, waypointSymbol);
    print(result);
} catch (e) {
    print('Exception when calling SystemsApi->getMarket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **systemSymbol** | **String**| The system symbol | 
 **waypointSymbol** | **String**| The waypoint symbol | 

### Return type

[**GetMarket200Response**](GetMarket200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getShipyard**
> GetShipyard200Response getShipyard(systemSymbol, waypointSymbol)

Get Shipyard

Get the shipyard for a waypoint. Send a ship to the waypoint to access ships that are currently available for purchase and recent transactions.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SystemsApi();
final systemSymbol = systemSymbol_example; // String | The system symbol
final waypointSymbol = waypointSymbol_example; // String | The waypoint symbol

try {
    final result = api_instance.getShipyard(systemSymbol, waypointSymbol);
    print(result);
} catch (e) {
    print('Exception when calling SystemsApi->getShipyard: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **systemSymbol** | **String**| The system symbol | 
 **waypointSymbol** | **String**| The waypoint symbol | 

### Return type

[**GetShipyard200Response**](GetShipyard200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSystem**
> GetSystem200Response getSystem(systemSymbol)

Get System

Get the details of a system.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SystemsApi();
final systemSymbol = systemSymbol_example; // String | The system symbol

try {
    final result = api_instance.getSystem(systemSymbol);
    print(result);
} catch (e) {
    print('Exception when calling SystemsApi->getSystem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **systemSymbol** | **String**| The system symbol | [default to 'X1-OE']

### Return type

[**GetSystem200Response**](GetSystem200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSystemWaypoints**
> GetSystemWaypoints200Response getSystemWaypoints(systemSymbol, page, limit)

List Waypoints

Fetch all of the waypoints for a given system. System must be charted or a ship must be present to return waypoint details.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SystemsApi();
final systemSymbol = systemSymbol_example; // String | The system symbol
final page = 56; // int | What entry offset to request
final limit = 56; // int | How many entries to return per page

try {
    final result = api_instance.getSystemWaypoints(systemSymbol, page, limit);
    print(result);
} catch (e) {
    print('Exception when calling SystemsApi->getSystemWaypoints: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **systemSymbol** | **String**| The system symbol | 
 **page** | **int**| What entry offset to request | [optional] 
 **limit** | **int**| How many entries to return per page | [optional] 

### Return type

[**GetSystemWaypoints200Response**](GetSystemWaypoints200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSystems**
> GetSystems200Response getSystems(page, limit)

List Systems

Return a list of all systems.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SystemsApi();
final page = 56; // int | What entry offset to request
final limit = 56; // int | How many entries to return per page

try {
    final result = api_instance.getSystems(page, limit);
    print(result);
} catch (e) {
    print('Exception when calling SystemsApi->getSystems: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**| What entry offset to request | [optional] 
 **limit** | **int**| How many entries to return per page | [optional] 

### Return type

[**GetSystems200Response**](GetSystems200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getWaypoint**
> GetWaypoint200Response getWaypoint(systemSymbol, waypointSymbol)

Get Waypoint

View the details of a waypoint.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SystemsApi();
final systemSymbol = systemSymbol_example; // String | The system symbol
final waypointSymbol = waypointSymbol_example; // String | The waypoint symbol

try {
    final result = api_instance.getWaypoint(systemSymbol, waypointSymbol);
    print(result);
} catch (e) {
    print('Exception when calling SystemsApi->getWaypoint: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **systemSymbol** | **String**| The system symbol | 
 **waypointSymbol** | **String**| The waypoint symbol | 

### Return type

[**GetWaypoint200Response**](GetWaypoint200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

