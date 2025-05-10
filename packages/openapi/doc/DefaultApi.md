# openapi.api.DefaultApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *https://api.spacetraders.io/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthGet**](DefaultApi.md#healthget) | **GET** /health | 
[**metricsGet**](DefaultApi.md#metricsget) | **GET** /metrics | 


# **healthGet**
> healthGet()



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

final api_instance = DefaultApi();

try {
    api_instance.healthGet();
} catch (e) {
    print('Exception when calling DefaultApi->healthGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[AccountToken](../README.md#AccountToken), [AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **metricsGet**
> metricsGet()



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

final api_instance = DefaultApi();

try {
    api_instance.metricsGet();
} catch (e) {
    print('Exception when calling DefaultApi->metricsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[AccountToken](../README.md#AccountToken), [AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

