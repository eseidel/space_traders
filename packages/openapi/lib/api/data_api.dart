//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class DataApi {
  DataApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Describes trade relationships
  ///
  /// Describes which import and exports map to each other.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getSupplyChainWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/market/supply-chain';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Describes trade relationships
  ///
  /// Describes which import and exports map to each other.
  Future<GetSupplyChain200Response?> getSupplyChain() async {
    final response = await getSupplyChainWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'GetSupplyChain200Response',
      ) as GetSupplyChain200Response;
    }
    return null;
  }

  /// Subscribe to events
  ///
  /// Subscribe to departure events for a system.                      ## WebSocket Events                      The following events are available:                      - `systems.{systemSymbol}.departure`: A ship has departed from the system.            ## Subscribe using a message with the following format:            ```json           {             \"action\": \"subscribe\",             \"systemSymbol\": \"{systemSymbol}\"           }           ```                      ## Unsubscribe using a message with the following format:            ```json           {             \"action\": \"unsubscribe\",             \"systemSymbol\": \"{systemSymbol}\"           }           ```
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> websocketDepartureEventsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/my/socket.io';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Subscribe to events
  ///
  /// Subscribe to departure events for a system.                      ## WebSocket Events                      The following events are available:                      - `systems.{systemSymbol}.departure`: A ship has departed from the system.            ## Subscribe using a message with the following format:            ```json           {             \"action\": \"subscribe\",             \"systemSymbol\": \"{systemSymbol}\"           }           ```                      ## Unsubscribe using a message with the following format:            ```json           {             \"action\": \"unsubscribe\",             \"systemSymbol\": \"{systemSymbol}\"           }           ```
  Future<void> websocketDepartureEvents() async {
    final response = await websocketDepartureEventsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
