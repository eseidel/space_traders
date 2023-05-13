# openapi.api.FleetApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *https://api.spacetraders.io/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createChart**](FleetApi.md#createchart) | **POST** /my/ships/{shipSymbol}/chart | Create Chart
[**createShipShipScan**](FleetApi.md#createshipshipscan) | **POST** /my/ships/{shipSymbol}/scan/ships | Scan Ships
[**createShipSystemScan**](FleetApi.md#createshipsystemscan) | **POST** /my/ships/{shipSymbol}/scan/systems | Scan Systems
[**createShipWaypointScan**](FleetApi.md#createshipwaypointscan) | **POST** /my/ships/{shipSymbol}/scan/waypoints | Scan Waypoints
[**createSurvey**](FleetApi.md#createsurvey) | **POST** /my/ships/{shipSymbol}/survey | Create Survey
[**dockShip**](FleetApi.md#dockship) | **POST** /my/ships/{shipSymbol}/dock | Dock Ship
[**extractResources**](FleetApi.md#extractresources) | **POST** /my/ships/{shipSymbol}/extract | Extract Resources
[**getMyShip**](FleetApi.md#getmyship) | **GET** /my/ships/{shipSymbol} | Get Ship
[**getMyShipCargo**](FleetApi.md#getmyshipcargo) | **GET** /my/ships/{shipSymbol}/cargo | Get Ship Cargo
[**getMyShips**](FleetApi.md#getmyships) | **GET** /my/ships | List Ships
[**getShipCooldown**](FleetApi.md#getshipcooldown) | **GET** /my/ships/{shipSymbol}/cooldown | Get Ship Cooldown
[**getShipNav**](FleetApi.md#getshipnav) | **GET** /my/ships/{shipSymbol}/nav | Get Ship Nav
[**jettison**](FleetApi.md#jettison) | **POST** /my/ships/{shipSymbol}/jettison | Jettison Cargo
[**jumpShip**](FleetApi.md#jumpship) | **POST** /my/ships/{shipSymbol}/jump | Jump Ship
[**navigateShip**](FleetApi.md#navigateship) | **POST** /my/ships/{shipSymbol}/navigate | Navigate Ship
[**orbitShip**](FleetApi.md#orbitship) | **POST** /my/ships/{shipSymbol}/orbit | Orbit Ship
[**patchShipNav**](FleetApi.md#patchshipnav) | **PATCH** /my/ships/{shipSymbol}/nav | Patch Ship Nav
[**purchaseCargo**](FleetApi.md#purchasecargo) | **POST** /my/ships/{shipSymbol}/purchase | Purchase Cargo
[**purchaseShip**](FleetApi.md#purchaseship) | **POST** /my/ships | Purchase Ship
[**refuelShip**](FleetApi.md#refuelship) | **POST** /my/ships/{shipSymbol}/refuel | Refuel Ship
[**sellCargo**](FleetApi.md#sellcargo) | **POST** /my/ships/{shipSymbol}/sell | Sell Cargo
[**shipRefine**](FleetApi.md#shiprefine) | **POST** /my/ships/{shipSymbol}/refine | Ship Refine
[**transferCargo**](FleetApi.md#transfercargo) | **POST** /my/ships/{shipSymbol}/transfer | Transfer Cargo
[**warpShip**](FleetApi.md#warpship) | **POST** /my/ships/{shipSymbol}/warp | Warp Ship


# **createChart**
> CreateChart201Response createChart(shipSymbol)

Create Chart

Command a ship to chart the current waypoint.  Waypoints in the universe are uncharted by default. These locations will not show up in the API until they have been charted by a ship.  Charting a location will record your agent as the one who created the chart.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The symbol of the ship

try {
    final result = api_instance.createChart(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->createChart: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The symbol of the ship | 

### Return type

[**CreateChart201Response**](CreateChart201Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createShipShipScan**
> CreateShipShipScan201Response createShipShipScan(shipSymbol)

Scan Ships

Activate your ship's sensor arrays to scan for ship information.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 

try {
    final result = api_instance.createShipShipScan(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->createShipShipScan: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 

### Return type

[**CreateShipShipScan201Response**](CreateShipShipScan201Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createShipSystemScan**
> CreateShipSystemScan201Response createShipSystemScan(shipSymbol)

Scan Systems

Activate your ship's sensor arrays to scan for system information.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 

try {
    final result = api_instance.createShipSystemScan(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->createShipSystemScan: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 

### Return type

[**CreateShipSystemScan201Response**](CreateShipSystemScan201Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createShipWaypointScan**
> CreateShipWaypointScan201Response createShipWaypointScan(shipSymbol)

Scan Waypoints

Activate your ship's sensor arrays to scan for waypoint information.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 

try {
    final result = api_instance.createShipWaypointScan(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->createShipWaypointScan: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 

### Return type

[**CreateShipWaypointScan201Response**](CreateShipWaypointScan201Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createSurvey**
> CreateSurvey201Response createSurvey(shipSymbol)

Create Survey

If you want to target specific yields for an extraction, you can survey a waypoint, such as an asteroid field, and send the survey in the body of the extract request. Each survey may have multiple deposits, and if a symbol shows up more than once, that indicates a higher chance of extracting that resource.  Your ship will enter a cooldown between consecutive survey requests. Surveys will eventually expire after a period of time. Multiple ships can use the same survey for extraction.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The symbol of the ship

try {
    final result = api_instance.createSurvey(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->createSurvey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The symbol of the ship | 

### Return type

[**CreateSurvey201Response**](CreateSurvey201Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **dockShip**
> DockShip200Response dockShip(shipSymbol)

Dock Ship

Attempt to dock your ship at it's current location. Docking will only succeed if the waypoint is a dockable location, and your ship is capable of docking at the time of the request.  The endpoint is idempotent - successive calls will succeed even if the ship is already docked.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The symbol of the ship

try {
    final result = api_instance.dockShip(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->dockShip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The symbol of the ship | 

### Return type

[**DockShip200Response**](DockShip200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **extractResources**
> ExtractResources201Response extractResources(shipSymbol, extractResourcesRequest)

Extract Resources

Extract resources from the waypoint into your ship. Send an optional survey as the payload to target specific yields.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The ship symbol
final extractResourcesRequest = ExtractResourcesRequest(); // ExtractResourcesRequest | 

try {
    final result = api_instance.extractResources(shipSymbol, extractResourcesRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->extractResources: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The ship symbol | 
 **extractResourcesRequest** | [**ExtractResourcesRequest**](ExtractResourcesRequest.md)|  | [optional] 

### Return type

[**ExtractResources201Response**](ExtractResources201Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyShip**
> GetMyShip200Response getMyShip(shipSymbol)

Get Ship

Retrieve the details of your ship.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 

try {
    final result = api_instance.getMyShip(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->getMyShip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 

### Return type

[**GetMyShip200Response**](GetMyShip200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyShipCargo**
> GetMyShipCargo200Response getMyShipCargo(shipSymbol)

Get Ship Cargo

Retrieve the cargo of your ship.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The symbol of the ship

try {
    final result = api_instance.getMyShipCargo(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->getMyShipCargo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The symbol of the ship | 

### Return type

[**GetMyShipCargo200Response**](GetMyShipCargo200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyShips**
> GetMyShips200Response getMyShips(page, limit)

List Ships

Retrieve all of your ships.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final page = 56; // int | What entry offset to request
final limit = 56; // int | How many entries to return per page

try {
    final result = api_instance.getMyShips(page, limit);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->getMyShips: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**| What entry offset to request | [optional] 
 **limit** | **int**| How many entries to return per page | [optional] 

### Return type

[**GetMyShips200Response**](GetMyShips200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getShipCooldown**
> GetShipCooldown200Response getShipCooldown(shipSymbol)

Get Ship Cooldown

Retrieve the details of your ship's reactor cooldown. Some actions such as activating your jump drive, scanning, or extracting resources taxes your reactor and results in a cooldown.  Your ship cannot perform additional actions until your cooldown has expired. The duration of your cooldown is relative to the power consumption of the related modules or mounts for the action taken.  Response returns a 204 status code (no-content) when the ship has no cooldown.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 

try {
    final result = api_instance.getShipCooldown(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->getShipCooldown: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 

### Return type

[**GetShipCooldown200Response**](GetShipCooldown200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getShipNav**
> GetShipNav200Response getShipNav(shipSymbol)

Get Ship Nav

Get the current nav status of a ship.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The ship symbol

try {
    final result = api_instance.getShipNav(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->getShipNav: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The ship symbol | 

### Return type

[**GetShipNav200Response**](GetShipNav200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **jettison**
> Jettison200Response jettison(shipSymbol, jettisonRequest)

Jettison Cargo

Jettison cargo from your ship's cargo hold.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 
final jettisonRequest = JettisonRequest(); // JettisonRequest | 

try {
    final result = api_instance.jettison(shipSymbol, jettisonRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->jettison: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 
 **jettisonRequest** | [**JettisonRequest**](JettisonRequest.md)|  | [optional] 

### Return type

[**Jettison200Response**](Jettison200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **jumpShip**
> JumpShip200Response jumpShip(shipSymbol, jumpShipRequest)

Jump Ship

Jump your ship instantly to a target system. Unlike other forms of navigation, jumping requires a unit of antimatter.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 
final jumpShipRequest = JumpShipRequest(); // JumpShipRequest | 

try {
    final result = api_instance.jumpShip(shipSymbol, jumpShipRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->jumpShip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 
 **jumpShipRequest** | [**JumpShipRequest**](JumpShipRequest.md)|  | [optional] 

### Return type

[**JumpShip200Response**](JumpShip200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **navigateShip**
> NavigateShip200Response navigateShip(shipSymbol, navigateShipRequest)

Navigate Ship

Navigate to a target destination. The destination must be located within the same system as the ship. Navigating will consume the necessary fuel and supplies from the ship's manifest, and will pay out crew wages from the agent's account.  The returned response will detail the route information including the expected time of arrival. Most ship actions are unavailable until the ship has arrived at it's destination.  To travel between systems, see the ship's warp or jump actions.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The ship symbol
final navigateShipRequest = NavigateShipRequest(); // NavigateShipRequest | 

try {
    final result = api_instance.navigateShip(shipSymbol, navigateShipRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->navigateShip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The ship symbol | 
 **navigateShipRequest** | [**NavigateShipRequest**](NavigateShipRequest.md)|  | [optional] 

### Return type

[**NavigateShip200Response**](NavigateShip200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **orbitShip**
> OrbitShip200Response orbitShip(shipSymbol)

Orbit Ship

Attempt to move your ship into orbit at it's current location. The request will only succeed if your ship is capable of moving into orbit at the time of the request.  The endpoint is idempotent - successive calls will succeed even if the ship is already in orbit.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The symbol of the ship

try {
    final result = api_instance.orbitShip(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->orbitShip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The symbol of the ship | 

### Return type

[**OrbitShip200Response**](OrbitShip200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **patchShipNav**
> GetShipNav200Response patchShipNav(shipSymbol, patchShipNavRequest)

Patch Ship Nav

Update the nav data of a ship, such as the flight mode.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The ship symbol
final patchShipNavRequest = PatchShipNavRequest(); // PatchShipNavRequest | 

try {
    final result = api_instance.patchShipNav(shipSymbol, patchShipNavRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->patchShipNav: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The ship symbol | 
 **patchShipNavRequest** | [**PatchShipNavRequest**](PatchShipNavRequest.md)|  | [optional] 

### Return type

[**GetShipNav200Response**](GetShipNav200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **purchaseCargo**
> PurchaseCargo201Response purchaseCargo(shipSymbol, purchaseCargoRequest)

Purchase Cargo

Purchase cargo.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 
final purchaseCargoRequest = PurchaseCargoRequest(); // PurchaseCargoRequest | 

try {
    final result = api_instance.purchaseCargo(shipSymbol, purchaseCargoRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->purchaseCargo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 
 **purchaseCargoRequest** | [**PurchaseCargoRequest**](PurchaseCargoRequest.md)|  | [optional] 

### Return type

[**PurchaseCargo201Response**](PurchaseCargo201Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **purchaseShip**
> PurchaseShip201Response purchaseShip(purchaseShipRequest)

Purchase Ship

Purchase a ship

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final purchaseShipRequest = PurchaseShipRequest(); // PurchaseShipRequest | 

try {
    final result = api_instance.purchaseShip(purchaseShipRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->purchaseShip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **purchaseShipRequest** | [**PurchaseShipRequest**](PurchaseShipRequest.md)|  | [optional] 

### Return type

[**PurchaseShip201Response**](PurchaseShip201Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refuelShip**
> RefuelShip200Response refuelShip(shipSymbol)

Refuel Ship

Refuel your ship from the local market.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 

try {
    final result = api_instance.refuelShip(shipSymbol);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->refuelShip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 

### Return type

[**RefuelShip200Response**](RefuelShip200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sellCargo**
> SellCargo201Response sellCargo(shipSymbol, sellCargoRequest)

Sell Cargo

Sell cargo.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 
final sellCargoRequest = SellCargoRequest(); // SellCargoRequest | 

try {
    final result = api_instance.sellCargo(shipSymbol, sellCargoRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->sellCargo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 
 **sellCargoRequest** | [**SellCargoRequest**](SellCargoRequest.md)|  | [optional] 

### Return type

[**SellCargo201Response**](SellCargo201Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **shipRefine**
> ShipRefine200Response shipRefine(shipSymbol, shipRefineRequest)

Ship Refine

Attempt to refine the raw materials on your ship. The request will only succeed if your ship is capable of refining at the time of the request.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | The symbol of the ship
final shipRefineRequest = ShipRefineRequest(); // ShipRefineRequest | 

try {
    final result = api_instance.shipRefine(shipSymbol, shipRefineRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->shipRefine: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**| The symbol of the ship | 
 **shipRefineRequest** | [**ShipRefineRequest**](ShipRefineRequest.md)|  | [optional] 

### Return type

[**ShipRefine200Response**](ShipRefine200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **transferCargo**
> TransferCargo200Response transferCargo(shipSymbol, transferCargoRequest)

Transfer Cargo

Transfer cargo between ships.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 
final transferCargoRequest = TransferCargoRequest(); // TransferCargoRequest | 

try {
    final result = api_instance.transferCargo(shipSymbol, transferCargoRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->transferCargo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 
 **transferCargoRequest** | [**TransferCargoRequest**](TransferCargoRequest.md)|  | [optional] 

### Return type

[**TransferCargo200Response**](TransferCargo200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **warpShip**
> NavigateShip200Response warpShip(shipSymbol, navigateShipRequest)

Warp Ship

Warp your ship to a target destination in another system. Warping will consume the necessary fuel and supplies from the ship's manifest, and will pay out crew wages from the agent's account.  The returned response will detail the route information including the expected time of arrival. Most ship actions are unavailable until the ship has arrived at it's destination.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: AgentToken
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('AgentToken').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FleetApi();
final shipSymbol = shipSymbol_example; // String | 
final navigateShipRequest = NavigateShipRequest(); // NavigateShipRequest | 

try {
    final result = api_instance.warpShip(shipSymbol, navigateShipRequest);
    print(result);
} catch (e) {
    print('Exception when calling FleetApi->warpShip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipSymbol** | **String**|  | 
 **navigateShipRequest** | [**NavigateShipRequest**](NavigateShipRequest.md)|  | [optional] 

### Return type

[**NavigateShip200Response**](NavigateShip200Response.md)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

