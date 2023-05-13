//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class SystemsApi {
  SystemsApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get Jump Gate
  ///
  /// Get jump gate details for a waypoint.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [String] waypointSymbol (required):
  ///   The waypoint symbol
  Future<Response> getJumpGateWithHttpInfo(
    String systemSymbol,
    String waypointSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/systems/{systemSymbol}/waypoints/{waypointSymbol}/jump-gate'
        .replaceAll('{systemSymbol}', systemSymbol)
        .replaceAll('{waypointSymbol}', waypointSymbol);

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

  /// Get Jump Gate
  ///
  /// Get jump gate details for a waypoint.
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [String] waypointSymbol (required):
  ///   The waypoint symbol
  Future<GetJumpGate200Response?> getJumpGate(
    String systemSymbol,
    String waypointSymbol,
  ) async {
    final response = await getJumpGateWithHttpInfo(
      systemSymbol,
      waypointSymbol,
    );
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
        'GetJumpGate200Response',
      ) as GetJumpGate200Response;
    }
    return null;
  }

  /// Get Market
  ///
  /// Retrieve imports, exports and exchange data from a marketplace. Imports can be sold, exports can be purchased, and exchange goods can be purchased or sold. Send a ship to the waypoint to access trade good prices and recent transactions.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [String] waypointSymbol (required):
  ///   The waypoint symbol
  Future<Response> getMarketWithHttpInfo(
    String systemSymbol,
    String waypointSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/systems/{systemSymbol}/waypoints/{waypointSymbol}/market'
        .replaceAll('{systemSymbol}', systemSymbol)
        .replaceAll('{waypointSymbol}', waypointSymbol);

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

  /// Get Market
  ///
  /// Retrieve imports, exports and exchange data from a marketplace. Imports can be sold, exports can be purchased, and exchange goods can be purchased or sold. Send a ship to the waypoint to access trade good prices and recent transactions.
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [String] waypointSymbol (required):
  ///   The waypoint symbol
  Future<GetMarket200Response?> getMarket(
    String systemSymbol,
    String waypointSymbol,
  ) async {
    final response = await getMarketWithHttpInfo(
      systemSymbol,
      waypointSymbol,
    );
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
        'GetMarket200Response',
      ) as GetMarket200Response;
    }
    return null;
  }

  /// Get Shipyard
  ///
  /// Get the shipyard for a waypoint. Send a ship to the waypoint to access ships that are currently available for purchase and recent transactions.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [String] waypointSymbol (required):
  ///   The waypoint symbol
  Future<Response> getShipyardWithHttpInfo(
    String systemSymbol,
    String waypointSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/systems/{systemSymbol}/waypoints/{waypointSymbol}/shipyard'
        .replaceAll('{systemSymbol}', systemSymbol)
        .replaceAll('{waypointSymbol}', waypointSymbol);

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

  /// Get Shipyard
  ///
  /// Get the shipyard for a waypoint. Send a ship to the waypoint to access ships that are currently available for purchase and recent transactions.
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [String] waypointSymbol (required):
  ///   The waypoint symbol
  Future<GetShipyard200Response?> getShipyard(
    String systemSymbol,
    String waypointSymbol,
  ) async {
    final response = await getShipyardWithHttpInfo(
      systemSymbol,
      waypointSymbol,
    );
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
        'GetShipyard200Response',
      ) as GetShipyard200Response;
    }
    return null;
  }

  /// Get System
  ///
  /// Get the details of a system.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  Future<Response> getSystemWithHttpInfo(
    String systemSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/systems/{systemSymbol}'.replaceAll('{systemSymbol}', systemSymbol);

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

  /// Get System
  ///
  /// Get the details of a system.
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  Future<GetSystem200Response?> getSystem(
    String systemSymbol,
  ) async {
    final response = await getSystemWithHttpInfo(
      systemSymbol,
    );
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
        'GetSystem200Response',
      ) as GetSystem200Response;
    }
    return null;
  }

  /// List Waypoints
  ///
  /// Fetch all of the waypoints for a given system. System must be charted or a ship must be present to return waypoint details.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [int] page:
  ///   What entry offset to request
  ///
  /// * [int] limit:
  ///   How many entries to return per page
  Future<Response> getSystemWaypointsWithHttpInfo(
    String systemSymbol, {
    int? page,
    int? limit,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/systems/{systemSymbol}/waypoints'
        .replaceAll('{systemSymbol}', systemSymbol);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

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

  /// List Waypoints
  ///
  /// Fetch all of the waypoints for a given system. System must be charted or a ship must be present to return waypoint details.
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [int] page:
  ///   What entry offset to request
  ///
  /// * [int] limit:
  ///   How many entries to return per page
  Future<GetSystemWaypoints200Response?> getSystemWaypoints(
    String systemSymbol, {
    int? page,
    int? limit,
  }) async {
    final response = await getSystemWaypointsWithHttpInfo(
      systemSymbol,
      page: page,
      limit: limit,
    );
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
        'GetSystemWaypoints200Response',
      ) as GetSystemWaypoints200Response;
    }
    return null;
  }

  /// List Systems
  ///
  /// Return a list of all systems.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///   What entry offset to request
  ///
  /// * [int] limit:
  ///   How many entries to return per page
  Future<Response> getSystemsWithHttpInfo({
    int? page,
    int? limit,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/systems';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

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

  /// List Systems
  ///
  /// Return a list of all systems.
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///   What entry offset to request
  ///
  /// * [int] limit:
  ///   How many entries to return per page
  Future<GetSystems200Response?> getSystems({
    int? page,
    int? limit,
  }) async {
    final response = await getSystemsWithHttpInfo(
      page: page,
      limit: limit,
    );
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
        'GetSystems200Response',
      ) as GetSystems200Response;
    }
    return null;
  }

  /// Get Waypoint
  ///
  /// View the details of a waypoint.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [String] waypointSymbol (required):
  ///   The waypoint symbol
  Future<Response> getWaypointWithHttpInfo(
    String systemSymbol,
    String waypointSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/systems/{systemSymbol}/waypoints/{waypointSymbol}'
        .replaceAll('{systemSymbol}', systemSymbol)
        .replaceAll('{waypointSymbol}', waypointSymbol);

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

  /// Get Waypoint
  ///
  /// View the details of a waypoint.
  ///
  /// Parameters:
  ///
  /// * [String] systemSymbol (required):
  ///   The system symbol
  ///
  /// * [String] waypointSymbol (required):
  ///   The waypoint symbol
  Future<GetWaypoint200Response?> getWaypoint(
    String systemSymbol,
    String waypointSymbol,
  ) async {
    final response = await getWaypointWithHttpInfo(
      systemSymbol,
      waypointSymbol,
    );
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
        'GetWaypoint200Response',
      ) as GetWaypoint200Response;
    }
    return null;
  }
}
