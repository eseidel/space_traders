# openapi.model.GetStatus200Response

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**status** | **String** | The current status of the game server. | 
**version** | **String** | The current version of the API. | 
**resetDate** | **String** | The date when the game server was last reset. | 
**description** | **String** |  | 
**stats** | [**GetStatus200ResponseStats**](GetStatus200ResponseStats.md) |  | 
**leaderboards** | [**GetStatus200ResponseLeaderboards**](GetStatus200ResponseLeaderboards.md) |  | 
**serverResets** | [**GetStatus200ResponseServerResets**](GetStatus200ResponseServerResets.md) |  | 
**announcements** | [**List<GetStatus200ResponseAnnouncementsInner>**](GetStatus200ResponseAnnouncementsInner.md) |  | [default to const []]
**links** | [**List<GetStatus200ResponseLinksInner>**](GetStatus200ResponseLinksInner.md) |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


