//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class FleetApi {
  FleetApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create Chart
  ///
  /// Command a ship to chart the waypoint at its current location.  Most waypoints in the universe are uncharted by default. These waypoints have their traits hidden until they have been charted by a ship.  Charting a waypoint will record your agent as the one who created the chart, and all other agents would also be able to see the waypoint's traits.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<Response> createChartWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/chart'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create Chart
  ///
  /// Command a ship to chart the waypoint at its current location.  Most waypoints in the universe are uncharted by default. These waypoints have their traits hidden until they have been charted by a ship.  Charting a waypoint will record your agent as the one who created the chart, and all other agents would also be able to see the waypoint's traits.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<CreateChart201Response?> createChart(
    String shipSymbol,
  ) async {
    final response = await createChartWithHttpInfo(
      shipSymbol,
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
        'CreateChart201Response',
      ) as CreateChart201Response;
    }
    return null;
  }

  /// Scan Ships
  ///
  /// Scan for nearby ships, retrieving information for all ships in range.  Requires a ship to have the `Sensor Array` mount installed to use.  The ship will enter a cooldown after using this function, during which it cannot execute certain actions.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  Future<Response> createShipShipScanWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/scan/ships'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Scan Ships
  ///
  /// Scan for nearby ships, retrieving information for all ships in range.  Requires a ship to have the `Sensor Array` mount installed to use.  The ship will enter a cooldown after using this function, during which it cannot execute certain actions.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  Future<CreateShipShipScan201Response?> createShipShipScan(
    String shipSymbol,
  ) async {
    final response = await createShipShipScanWithHttpInfo(
      shipSymbol,
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
        'CreateShipShipScan201Response',
      ) as CreateShipShipScan201Response;
    }
    return null;
  }

  /// Scan Systems
  ///
  /// Scan for nearby systems, retrieving information on the systems' distance from the ship and their waypoints. Requires a ship to have the `Sensor Array` mount installed to use.  The ship will enter a cooldown after using this function, during which it cannot execute certain actions.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  Future<Response> createShipSystemScanWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/scan/systems'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Scan Systems
  ///
  /// Scan for nearby systems, retrieving information on the systems' distance from the ship and their waypoints. Requires a ship to have the `Sensor Array` mount installed to use.  The ship will enter a cooldown after using this function, during which it cannot execute certain actions.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  Future<CreateShipSystemScan201Response?> createShipSystemScan(
    String shipSymbol,
  ) async {
    final response = await createShipSystemScanWithHttpInfo(
      shipSymbol,
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
        'CreateShipSystemScan201Response',
      ) as CreateShipSystemScan201Response;
    }
    return null;
  }

  /// Scan Waypoints
  ///
  /// Scan for nearby waypoints, retrieving detailed information on each waypoint in range. Scanning uncharted waypoints will allow you to ignore their uncharted state and will list the waypoints' traits.  Requires a ship to have the `Sensor Array` mount installed to use.  The ship will enter a cooldown after using this function, during which it cannot execute certain actions.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  Future<Response> createShipWaypointScanWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/scan/waypoints'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Scan Waypoints
  ///
  /// Scan for nearby waypoints, retrieving detailed information on each waypoint in range. Scanning uncharted waypoints will allow you to ignore their uncharted state and will list the waypoints' traits.  Requires a ship to have the `Sensor Array` mount installed to use.  The ship will enter a cooldown after using this function, during which it cannot execute certain actions.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  Future<CreateShipWaypointScan201Response?> createShipWaypointScan(
    String shipSymbol,
  ) async {
    final response = await createShipWaypointScanWithHttpInfo(
      shipSymbol,
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
        'CreateShipWaypointScan201Response',
      ) as CreateShipWaypointScan201Response;
    }
    return null;
  }

  /// Create Survey
  ///
  /// Create surveys on a waypoint that can be extracted such as asteroid fields. A survey focuses on specific types of deposits from the extracted location. When ships extract using this survey, they are guaranteed to procure a high amount of one of the goods in the survey.  In order to use a survey, send the entire survey details in the body of the extract request.  Each survey may have multiple deposits, and if a symbol shows up more than once, that indicates a higher chance of extracting that resource.  Your ship will enter a cooldown after surveying in which it is unable to perform certain actions. Surveys will eventually expire after a period of time or will be exhausted after being extracted several times based on the survey's size. Multiple ships can use the same survey for extraction.  A ship must have the `Surveyor` mount installed in order to use this function.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<Response> createSurveyWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/survey'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create Survey
  ///
  /// Create surveys on a waypoint that can be extracted such as asteroid fields. A survey focuses on specific types of deposits from the extracted location. When ships extract using this survey, they are guaranteed to procure a high amount of one of the goods in the survey.  In order to use a survey, send the entire survey details in the body of the extract request.  Each survey may have multiple deposits, and if a symbol shows up more than once, that indicates a higher chance of extracting that resource.  Your ship will enter a cooldown after surveying in which it is unable to perform certain actions. Surveys will eventually expire after a period of time or will be exhausted after being extracted several times based on the survey's size. Multiple ships can use the same survey for extraction.  A ship must have the `Surveyor` mount installed in order to use this function.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<CreateSurvey201Response?> createSurvey(
    String shipSymbol,
  ) async {
    final response = await createSurveyWithHttpInfo(
      shipSymbol,
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
        'CreateSurvey201Response',
      ) as CreateSurvey201Response;
    }
    return null;
  }

  /// Dock Ship
  ///
  /// Attempt to dock your ship at its current location. Docking will only succeed if your ship is capable of docking at the time of the request.  Docked ships can access elements in their current location, such as the market or a shipyard, but cannot do actions that require the ship to be above surface such as navigating or extracting.  The endpoint is idempotent - successive calls will succeed even if the ship is already docked.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<Response> dockShipWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/dock'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Dock Ship
  ///
  /// Attempt to dock your ship at its current location. Docking will only succeed if your ship is capable of docking at the time of the request.  Docked ships can access elements in their current location, such as the market or a shipyard, but cannot do actions that require the ship to be above surface such as navigating or extracting.  The endpoint is idempotent - successive calls will succeed even if the ship is already docked.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<DockShip200Response?> dockShip(
    String shipSymbol,
  ) async {
    final response = await dockShipWithHttpInfo(
      shipSymbol,
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
        'DockShip200Response',
      ) as DockShip200Response;
    }
    return null;
  }

  /// Extract Resources
  ///
  /// Extract resources from a waypoint that can be extracted, such as asteroid fields, into your ship. Send an optional survey as the payload to target specific yields.  The ship must be in orbit to be able to extract and must have mining equipments installed that can extract goods, such as the `Gas Siphon` mount for gas-based goods or `Mining Laser` mount for ore-based goods.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [ExtractResourcesRequest] extractResourcesRequest:
  Future<Response> extractResourcesWithHttpInfo(
    String shipSymbol, {
    ExtractResourcesRequest? extractResourcesRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/extract'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = extractResourcesRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Extract Resources
  ///
  /// Extract resources from a waypoint that can be extracted, such as asteroid fields, into your ship. Send an optional survey as the payload to target specific yields.  The ship must be in orbit to be able to extract and must have mining equipments installed that can extract goods, such as the `Gas Siphon` mount for gas-based goods or `Mining Laser` mount for ore-based goods.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [ExtractResourcesRequest] extractResourcesRequest:
  Future<ExtractResources201Response?> extractResources(
    String shipSymbol, {
    ExtractResourcesRequest? extractResourcesRequest,
  }) async {
    final response = await extractResourcesWithHttpInfo(
      shipSymbol,
      extractResourcesRequest: extractResourcesRequest,
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
        'ExtractResources201Response',
      ) as ExtractResources201Response;
    }
    return null;
  }

  /// Get Mounts
  ///
  /// Get the mounts installed on a ship.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  Future<Response> getMountsWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/mounts'.replaceAll('{shipSymbol}', shipSymbol);

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

  /// Get Mounts
  ///
  /// Get the mounts installed on a ship.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  Future<GetMounts200Response?> getMounts(
    String shipSymbol,
  ) async {
    final response = await getMountsWithHttpInfo(
      shipSymbol,
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
        'GetMounts200Response',
      ) as GetMounts200Response;
    }
    return null;
  }

  /// Get Ship
  ///
  /// Retrieve the details of a ship under your agent's ownership.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<Response> getMyShipWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}'.replaceAll('{shipSymbol}', shipSymbol);

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

  /// Get Ship
  ///
  /// Retrieve the details of a ship under your agent's ownership.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<GetMyShip200Response?> getMyShip(
    String shipSymbol,
  ) async {
    final response = await getMyShipWithHttpInfo(
      shipSymbol,
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
        'GetMyShip200Response',
      ) as GetMyShip200Response;
    }
    return null;
  }

  /// Get Ship Cargo
  ///
  /// Retrieve the cargo of a ship under your agent's ownership.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<Response> getMyShipCargoWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/cargo'.replaceAll('{shipSymbol}', shipSymbol);

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

  /// Get Ship Cargo
  ///
  /// Retrieve the cargo of a ship under your agent's ownership.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<GetMyShipCargo200Response?> getMyShipCargo(
    String shipSymbol,
  ) async {
    final response = await getMyShipCargoWithHttpInfo(
      shipSymbol,
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
        'GetMyShipCargo200Response',
      ) as GetMyShipCargo200Response;
    }
    return null;
  }

  /// List Ships
  ///
  /// Return a paginated list of all of ships under your agent's ownership.
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
  Future<Response> getMyShipsWithHttpInfo({
    int? page,
    int? limit,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships';

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

  /// List Ships
  ///
  /// Return a paginated list of all of ships under your agent's ownership.
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///   What entry offset to request
  ///
  /// * [int] limit:
  ///   How many entries to return per page
  Future<GetMyShips200Response?> getMyShips({
    int? page,
    int? limit,
  }) async {
    final response = await getMyShipsWithHttpInfo(
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
        'GetMyShips200Response',
      ) as GetMyShips200Response;
    }
    return null;
  }

  /// Get Ship Cooldown
  ///
  /// Retrieve the details of your ship's reactor cooldown. Some actions such as activating your jump drive, scanning, or extracting resources taxes your reactor and results in a cooldown.  Your ship cannot perform additional actions until your cooldown has expired. The duration of your cooldown is relative to the power consumption of the related modules or mounts for the action taken.  Response returns a 204 status code (no-content) when the ship has no cooldown.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<Response> getShipCooldownWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/cooldown'
        .replaceAll('{shipSymbol}', shipSymbol);

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

  /// Get Ship Cooldown
  ///
  /// Retrieve the details of your ship's reactor cooldown. Some actions such as activating your jump drive, scanning, or extracting resources taxes your reactor and results in a cooldown.  Your ship cannot perform additional actions until your cooldown has expired. The duration of your cooldown is relative to the power consumption of the related modules or mounts for the action taken.  Response returns a 204 status code (no-content) when the ship has no cooldown.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<GetShipCooldown200Response?> getShipCooldown(
    String shipSymbol,
  ) async {
    final response = await getShipCooldownWithHttpInfo(
      shipSymbol,
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
        'GetShipCooldown200Response',
      ) as GetShipCooldown200Response;
    }
    return null;
  }

  /// Get Ship Nav
  ///
  /// Get the current nav status of a ship.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  Future<Response> getShipNavWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/nav'.replaceAll('{shipSymbol}', shipSymbol);

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

  /// Get Ship Nav
  ///
  /// Get the current nav status of a ship.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  Future<GetShipNav200Response?> getShipNav(
    String shipSymbol,
  ) async {
    final response = await getShipNavWithHttpInfo(
      shipSymbol,
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
        'GetShipNav200Response',
      ) as GetShipNav200Response;
    }
    return null;
  }

  /// Install Mount
  ///
  /// Install a mount on a ship.  In order to install a mount, the ship must be docked and located in a waypoint that has a `Shipyard` trait. The ship also must have the mount to install in its cargo hold.  An installation fee will be deduced by the Shipyard for installing the mount on the ship.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  ///
  /// * [InstallMountRequest] installMountRequest:
  Future<Response> installMountWithHttpInfo(
    String shipSymbol, {
    InstallMountRequest? installMountRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/mounts/install'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = installMountRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Install Mount
  ///
  /// Install a mount on a ship.  In order to install a mount, the ship must be docked and located in a waypoint that has a `Shipyard` trait. The ship also must have the mount to install in its cargo hold.  An installation fee will be deduced by the Shipyard for installing the mount on the ship.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  ///
  /// * [InstallMountRequest] installMountRequest:
  Future<InstallMount201Response?> installMount(
    String shipSymbol, {
    InstallMountRequest? installMountRequest,
  }) async {
    final response = await installMountWithHttpInfo(
      shipSymbol,
      installMountRequest: installMountRequest,
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
        'InstallMount201Response',
      ) as InstallMount201Response;
    }
    return null;
  }

  /// Jettison Cargo
  ///
  /// Jettison cargo from your ship's cargo hold.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [JettisonRequest] jettisonRequest:
  Future<Response> jettisonWithHttpInfo(
    String shipSymbol, {
    JettisonRequest? jettisonRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/jettison'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = jettisonRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Jettison Cargo
  ///
  /// Jettison cargo from your ship's cargo hold.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [JettisonRequest] jettisonRequest:
  Future<Jettison200Response?> jettison(
    String shipSymbol, {
    JettisonRequest? jettisonRequest,
  }) async {
    final response = await jettisonWithHttpInfo(
      shipSymbol,
      jettisonRequest: jettisonRequest,
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
        'Jettison200Response',
      ) as Jettison200Response;
    }
    return null;
  }

  /// Jump Ship
  ///
  /// Jump your ship instantly to a target system. The ship must be in orbit to use this function. When used while in orbit of a Jump Gate waypoint, any ship can use this command, jumping to the target system's Jump Gate waypoint.  When used elsewhere, jumping requires the ship to have a `Jump Drive` module installed and consumes a unit of antimatter from the ship's cargo. The command will fail if there is no antimatter to consume. When jumping via the `Jump Drive` module, the ship ends up at its largest source of energy in the system, such as a gas planet or a jump gate.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [JumpShipRequest] jumpShipRequest:
  Future<Response> jumpShipWithHttpInfo(
    String shipSymbol, {
    JumpShipRequest? jumpShipRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/jump'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = jumpShipRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Jump Ship
  ///
  /// Jump your ship instantly to a target system. The ship must be in orbit to use this function. When used while in orbit of a Jump Gate waypoint, any ship can use this command, jumping to the target system's Jump Gate waypoint.  When used elsewhere, jumping requires the ship to have a `Jump Drive` module installed and consumes a unit of antimatter from the ship's cargo. The command will fail if there is no antimatter to consume. When jumping via the `Jump Drive` module, the ship ends up at its largest source of energy in the system, such as a gas planet or a jump gate.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [JumpShipRequest] jumpShipRequest:
  Future<JumpShip200Response?> jumpShip(
    String shipSymbol, {
    JumpShipRequest? jumpShipRequest,
  }) async {
    final response = await jumpShipWithHttpInfo(
      shipSymbol,
      jumpShipRequest: jumpShipRequest,
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
        'JumpShip200Response',
      ) as JumpShip200Response;
    }
    return null;
  }

  /// Navigate Ship
  ///
  /// Navigate to a target destination. The ship must be in orbit to use this function. The destination waypoint must be within the same system as the ship's current location. Navigating will consume the necessary fuel from the ship's manifest based on the distance to the target waypoint.  The returned response will detail the route information including the expected time of arrival. Most ship actions are unavailable until the ship has arrived at it's destination.  To travel between systems, see the ship's Warp or Jump actions.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [NavigateShipRequest] navigateShipRequest:
  ///
  Future<Response> navigateShipWithHttpInfo(
    String shipSymbol, {
    NavigateShipRequest? navigateShipRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/navigate'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = navigateShipRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Navigate Ship
  ///
  /// Navigate to a target destination. The ship must be in orbit to use this function. The destination waypoint must be within the same system as the ship's current location. Navigating will consume the necessary fuel from the ship's manifest based on the distance to the target waypoint.  The returned response will detail the route information including the expected time of arrival. Most ship actions are unavailable until the ship has arrived at it's destination.  To travel between systems, see the ship's Warp or Jump actions.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [NavigateShipRequest] navigateShipRequest:
  ///
  Future<NavigateShip200Response?> navigateShip(
    String shipSymbol, {
    NavigateShipRequest? navigateShipRequest,
  }) async {
    final response = await navigateShipWithHttpInfo(
      shipSymbol,
      navigateShipRequest: navigateShipRequest,
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
        'NavigateShip200Response',
      ) as NavigateShip200Response;
    }
    return null;
  }

  /// Negotiate Contract
  ///
  /// Negotiate a new contract with the HQ.  In order to negotiate a new contract, an agent must not have ongoing or offered contracts over the allowed maximum amount. Currently the maximum contracts an agent can have at a time is 1.  Once a contract is negotiated, it is added to the list of contracts offered to the agent, which the agent can then accept.   The ship must be present at a faction's HQ waypoint to negotiate a contract with that faction.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  Future<Response> negotiateContractWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/negotiate/contract'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Negotiate Contract
  ///
  /// Negotiate a new contract with the HQ.  In order to negotiate a new contract, an agent must not have ongoing or offered contracts over the allowed maximum amount. Currently the maximum contracts an agent can have at a time is 1.  Once a contract is negotiated, it is added to the list of contracts offered to the agent, which the agent can then accept.   The ship must be present at a faction's HQ waypoint to negotiate a contract with that faction.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  Future<NegotiateContract200Response?> negotiateContract(
    String shipSymbol,
  ) async {
    final response = await negotiateContractWithHttpInfo(
      shipSymbol,
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
        'NegotiateContract200Response',
      ) as NegotiateContract200Response;
    }
    return null;
  }

  /// Orbit Ship
  ///
  /// Attempt to move your ship into orbit at its current location. The request will only succeed if your ship is capable of moving into orbit at the time of the request.  Orbiting ships are able to do actions that require the ship to be above surface such as navigating or extracting, but cannot access elements in their current waypoint, such as the market or a shipyard.  The endpoint is idempotent - successive calls will succeed even if the ship is already in orbit.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<Response> orbitShipWithHttpInfo(
    String shipSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/orbit'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Orbit Ship
  ///
  /// Attempt to move your ship into orbit at its current location. The request will only succeed if your ship is capable of moving into orbit at the time of the request.  Orbiting ships are able to do actions that require the ship to be above surface such as navigating or extracting, but cannot access elements in their current waypoint, such as the market or a shipyard.  The endpoint is idempotent - successive calls will succeed even if the ship is already in orbit.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  Future<OrbitShip200Response?> orbitShip(
    String shipSymbol,
  ) async {
    final response = await orbitShipWithHttpInfo(
      shipSymbol,
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
        'OrbitShip200Response',
      ) as OrbitShip200Response;
    }
    return null;
  }

  /// Patch Ship Nav
  ///
  /// Update the nav configuration of a ship.  Currently only supports configuring the Flight Mode of the ship, which affects its speed and fuel consumption.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [PatchShipNavRequest] patchShipNavRequest:
  Future<Response> patchShipNavWithHttpInfo(
    String shipSymbol, {
    PatchShipNavRequest? patchShipNavRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/nav'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = patchShipNavRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Patch Ship Nav
  ///
  /// Update the nav configuration of a ship.  Currently only supports configuring the Flight Mode of the ship, which affects its speed and fuel consumption.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [PatchShipNavRequest] patchShipNavRequest:
  Future<GetShipNav200Response?> patchShipNav(
    String shipSymbol, {
    PatchShipNavRequest? patchShipNavRequest,
  }) async {
    final response = await patchShipNavWithHttpInfo(
      shipSymbol,
      patchShipNavRequest: patchShipNavRequest,
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
        'GetShipNav200Response',
      ) as GetShipNav200Response;
    }
    return null;
  }

  /// Purchase Cargo
  ///
  /// Purchase cargo from a market.  The ship must be docked in a waypoint that has `Marketplace` trait, and the market must be selling a good to be able to purchase it.  The maximum amount of units of a good that can be purchased in each transaction are denoted by the `tradeVolume` value of the good, which can be viewed by using the Get Market action.  Purchased goods are added to the ship's cargo hold.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  ///
  /// * [PurchaseCargoRequest] purchaseCargoRequest:
  Future<Response> purchaseCargoWithHttpInfo(
    String shipSymbol, {
    PurchaseCargoRequest? purchaseCargoRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/purchase'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = purchaseCargoRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Purchase Cargo
  ///
  /// Purchase cargo from a market.  The ship must be docked in a waypoint that has `Marketplace` trait, and the market must be selling a good to be able to purchase it.  The maximum amount of units of a good that can be purchased in each transaction are denoted by the `tradeVolume` value of the good, which can be viewed by using the Get Market action.  Purchased goods are added to the ship's cargo hold.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  ///
  /// * [PurchaseCargoRequest] purchaseCargoRequest:
  Future<PurchaseCargo201Response?> purchaseCargo(
    String shipSymbol, {
    PurchaseCargoRequest? purchaseCargoRequest,
  }) async {
    final response = await purchaseCargoWithHttpInfo(
      shipSymbol,
      purchaseCargoRequest: purchaseCargoRequest,
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
        'PurchaseCargo201Response',
      ) as PurchaseCargo201Response;
    }
    return null;
  }

  /// Purchase Ship
  ///
  /// Purchase a ship from a Shipyard. In order to use this function, a ship under your agent's ownership must be in a waypoint that has the `Shipyard` trait, and the Shipyard must sell the type of the desired ship.  Shipyards typically offer ship types, which are predefined templates of ships that have dedicated roles. A template comes with a preset of an engine, a reactor, and a frame. It may also include a few modules and mounts.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PurchaseShipRequest] purchaseShipRequest:
  Future<Response> purchaseShipWithHttpInfo({
    PurchaseShipRequest? purchaseShipRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships';

    // ignore: prefer_final_locals
    Object? postBody = purchaseShipRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Purchase Ship
  ///
  /// Purchase a ship from a Shipyard. In order to use this function, a ship under your agent's ownership must be in a waypoint that has the `Shipyard` trait, and the Shipyard must sell the type of the desired ship.  Shipyards typically offer ship types, which are predefined templates of ships that have dedicated roles. A template comes with a preset of an engine, a reactor, and a frame. It may also include a few modules and mounts.
  ///
  /// Parameters:
  ///
  /// * [PurchaseShipRequest] purchaseShipRequest:
  Future<PurchaseShip201Response?> purchaseShip({
    PurchaseShipRequest? purchaseShipRequest,
  }) async {
    final response = await purchaseShipWithHttpInfo(
      purchaseShipRequest: purchaseShipRequest,
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
        'PurchaseShip201Response',
      ) as PurchaseShip201Response;
    }
    return null;
  }

  /// Refuel Ship
  ///
  /// Refuel your ship by buying fuel from the local market.  Requires the ship to be docked in a waypoint that has the `Marketplace` trait, and the market must be selling fuel in order to refuel.  Each fuel bought from the market replenishes 100 units in your ship's fuel.  Ships will always be refuel to their frame's maximum fuel capacity when using this action.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [RefuelShipRequest] refuelShipRequest:
  Future<Response> refuelShipWithHttpInfo(
    String shipSymbol, {
    RefuelShipRequest? refuelShipRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/refuel'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = refuelShipRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Refuel Ship
  ///
  /// Refuel your ship by buying fuel from the local market.  Requires the ship to be docked in a waypoint that has the `Marketplace` trait, and the market must be selling fuel in order to refuel.  Each fuel bought from the market replenishes 100 units in your ship's fuel.  Ships will always be refuel to their frame's maximum fuel capacity when using this action.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [RefuelShipRequest] refuelShipRequest:
  Future<RefuelShip200Response?> refuelShip(
    String shipSymbol, {
    RefuelShipRequest? refuelShipRequest,
  }) async {
    final response = await refuelShipWithHttpInfo(
      shipSymbol,
      refuelShipRequest: refuelShipRequest,
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
        'RefuelShip200Response',
      ) as RefuelShip200Response;
    }
    return null;
  }

  /// Remove Mount
  ///
  /// Remove a mount from a ship.  The ship must be docked in a waypoint that has the `Shipyard` trait, and must have the desired mount that it wish to remove installed.  A removal fee will be deduced from the agent by the Shipyard.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  ///
  /// * [RemoveMountRequest] removeMountRequest:
  Future<Response> removeMountWithHttpInfo(
    String shipSymbol, {
    RemoveMountRequest? removeMountRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/mounts/remove'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = removeMountRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Remove Mount
  ///
  /// Remove a mount from a ship.  The ship must be docked in a waypoint that has the `Shipyard` trait, and must have the desired mount that it wish to remove installed.  A removal fee will be deduced from the agent by the Shipyard.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship's symbol.
  ///
  /// * [RemoveMountRequest] removeMountRequest:
  Future<RemoveMount201Response?> removeMount(
    String shipSymbol, {
    RemoveMountRequest? removeMountRequest,
  }) async {
    final response = await removeMountWithHttpInfo(
      shipSymbol,
      removeMountRequest: removeMountRequest,
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
        'RemoveMount201Response',
      ) as RemoveMount201Response;
    }
    return null;
  }

  /// Sell Cargo
  ///
  /// Sell cargo in your ship to a market that trades this cargo. The ship must be docked in a waypoint that has the `Marketplace` trait in order to use this function.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   Symbol of a ship.
  ///
  /// * [SellCargoRequest] sellCargoRequest:
  Future<Response> sellCargoWithHttpInfo(
    String shipSymbol, {
    SellCargoRequest? sellCargoRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/sell'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = sellCargoRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Sell Cargo
  ///
  /// Sell cargo in your ship to a market that trades this cargo. The ship must be docked in a waypoint that has the `Marketplace` trait in order to use this function.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   Symbol of a ship.
  ///
  /// * [SellCargoRequest] sellCargoRequest:
  Future<SellCargo201Response?> sellCargo(
    String shipSymbol, {
    SellCargoRequest? sellCargoRequest,
  }) async {
    final response = await sellCargoWithHttpInfo(
      shipSymbol,
      sellCargoRequest: sellCargoRequest,
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
        'SellCargo201Response',
      ) as SellCargo201Response;
    }
    return null;
  }

  /// Ship Refine
  ///
  /// Attempt to refine the raw materials on your ship. The request will only succeed if your ship is capable of refining at the time of the request. In order to be able to refine, a ship must have goods that can be refined and have installed a `Refinery` module that can refine it.  When refining, 30 basic goods will be converted into 10 processed goods.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  ///
  /// * [ShipRefineRequest] shipRefineRequest:
  Future<Response> shipRefineWithHttpInfo(
    String shipSymbol, {
    ShipRefineRequest? shipRefineRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/refine'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = shipRefineRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Ship Refine
  ///
  /// Attempt to refine the raw materials on your ship. The request will only succeed if your ship is capable of refining at the time of the request. In order to be able to refine, a ship must have goods that can be refined and have installed a `Refinery` module that can refine it.  When refining, 30 basic goods will be converted into 10 processed goods.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The symbol of the ship.
  ///
  /// * [ShipRefineRequest] shipRefineRequest:
  Future<ShipRefine201Response?> shipRefine(
    String shipSymbol, {
    ShipRefineRequest? shipRefineRequest,
  }) async {
    final response = await shipRefineWithHttpInfo(
      shipSymbol,
      shipRefineRequest: shipRefineRequest,
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
        'ShipRefine201Response',
      ) as ShipRefine201Response;
    }
    return null;
  }

  /// Transfer Cargo
  ///
  /// Transfer cargo between ships.  The receiving ship must be in the same waypoint as the transferring ship, and it must able to hold the additional cargo after the transfer is complete. Both ships also must be in the same state, either both are docked or both are orbiting.  The response body's cargo shows the cargo of the transferring ship after the transfer is complete.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The transferring ship's symbol.
  ///
  /// * [TransferCargoRequest] transferCargoRequest:
  Future<Response> transferCargoWithHttpInfo(
    String shipSymbol, {
    TransferCargoRequest? transferCargoRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/ships/{shipSymbol}/transfer'
        .replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = transferCargoRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Transfer Cargo
  ///
  /// Transfer cargo between ships.  The receiving ship must be in the same waypoint as the transferring ship, and it must able to hold the additional cargo after the transfer is complete. Both ships also must be in the same state, either both are docked or both are orbiting.  The response body's cargo shows the cargo of the transferring ship after the transfer is complete.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The transferring ship's symbol.
  ///
  /// * [TransferCargoRequest] transferCargoRequest:
  Future<TransferCargo200Response?> transferCargo(
    String shipSymbol, {
    TransferCargoRequest? transferCargoRequest,
  }) async {
    final response = await transferCargoWithHttpInfo(
      shipSymbol,
      transferCargoRequest: transferCargoRequest,
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
        'TransferCargo200Response',
      ) as TransferCargo200Response;
    }
    return null;
  }

  /// Warp Ship
  ///
  /// Warp your ship to a target destination in another system. The ship must be in orbit to use this function and must have the `Warp Drive` module installed. Warping will consume the necessary fuel from the ship's manifest.  The returned response will detail the route information including the expected time of arrival. Most ship actions are unavailable until the ship has arrived at its destination.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [NavigateShipRequest] navigateShipRequest:
  ///
  Future<Response> warpShipWithHttpInfo(
    String shipSymbol, {
    NavigateShipRequest? navigateShipRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/ships/{shipSymbol}/warp'.replaceAll('{shipSymbol}', shipSymbol);

    // ignore: prefer_final_locals
    Object? postBody = navigateShipRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Warp Ship
  ///
  /// Warp your ship to a target destination in another system. The ship must be in orbit to use this function and must have the `Warp Drive` module installed. Warping will consume the necessary fuel from the ship's manifest.  The returned response will detail the route information including the expected time of arrival. Most ship actions are unavailable until the ship has arrived at its destination.
  ///
  /// Parameters:
  ///
  /// * [String] shipSymbol (required):
  ///   The ship symbol.
  ///
  /// * [NavigateShipRequest] navigateShipRequest:
  ///
  Future<NavigateShip200Response?> warpShip(
    String shipSymbol, {
    NavigateShipRequest? navigateShipRequest,
  }) async {
    final response = await warpShipWithHttpInfo(
      shipSymbol,
      navigateShipRequest: navigateShipRequest,
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
        'NavigateShip200Response',
      ) as NavigateShip200Response;
    }
    return null;
  }
}
