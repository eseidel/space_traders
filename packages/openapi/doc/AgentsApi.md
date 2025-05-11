# openapi.api.AgentsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *https://api.spacetraders.io/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAgent**](AgentsApi.md#getagent) | **GET** /agents/{agentSymbol} | Get public details for a specific agent.
[**getAgents**](AgentsApi.md#getagents) | **GET** /agents | List all public agent details.
[**getMyAgent**](AgentsApi.md#getmyagent) | **GET** /my/agent | Get Agent
[**getMyAgentEvents**](AgentsApi.md#getmyagentevents) | **GET** /my/agent/events | Get Agent Events


# **getAgent**
> GetAgent200Response getAgent(agentSymbol)

Get public details for a specific agent.

Get public details for a specific agent.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AgentsApi();
final agentSymbol = FEBA66; // String | The agent symbol

try {
    final result = api_instance.getAgent(agentSymbol);
    print(result);
} catch (e) {
    print('Exception when calling AgentsApi->getAgent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **agentSymbol** | **String**| The agent symbol | 

### Return type

[**GetAgent200Response**](GetAgent200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAgents**
> GetAgents200Response getAgents(page, limit)

List all public agent details.

List all public agent details.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AgentsApi();
final page = 1; // int | What entry offset to request
final limit = 10; // int | How many entries to return per page

try {
    final result = api_instance.getAgents(page, limit);
    print(result);
} catch (e) {
    print('Exception when calling AgentsApi->getAgents: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**| What entry offset to request | [optional] [default to 1]
 **limit** | **int**| How many entries to return per page | [optional] [default to 10]

### Return type

[**GetAgents200Response**](GetAgents200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyAgent**
> GetMyAgent200Response getMyAgent()

Get Agent

Fetch your agent's details.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AgentsApi();

try {
    final result = api_instance.getMyAgent();
    print(result);
} catch (e) {
    print('Exception when calling AgentsApi->getMyAgent: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**GetMyAgent200Response**](GetMyAgent200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyAgentEvents**
> GetMyAgentEvents200Response getMyAgentEvents()

Get Agent Events

Get recent events for your agent.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AgentsApi();

try {
    final result = api_instance.getMyAgentEvents();
    print(result);
} catch (e) {
    print('Exception when calling AgentsApi->getMyAgentEvents: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**GetMyAgentEvents200Response**](GetMyAgentEvents200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

