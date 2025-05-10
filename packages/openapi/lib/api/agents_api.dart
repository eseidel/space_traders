//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class AgentsApi {
  AgentsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get public details for a specific agent.
  ///
  /// Get public details for a specific agent.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] agentSymbol (required):
  ///   The agent symbol
  Future<Response> getAgentWithHttpInfo(
    String agentSymbol,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/agents/{agentSymbol}'.replaceAll('{agentSymbol}', agentSymbol);

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

  /// Get public details for a specific agent.
  ///
  /// Get public details for a specific agent.
  ///
  /// Parameters:
  ///
  /// * [String] agentSymbol (required):
  ///   The agent symbol
  Future<GetAgent200Response?> getAgent(
    String agentSymbol,
  ) async {
    final response = await getAgentWithHttpInfo(
      agentSymbol,
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
        'GetAgent200Response',
      ) as GetAgent200Response;
    }
    return null;
  }

  /// List all public agent details.
  ///
  /// List all public agent details.
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
  Future<Response> getAgentsWithHttpInfo({
    int? page,
    int? limit,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/agents';

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

  /// List all public agent details.
  ///
  /// List all public agent details.
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///   What entry offset to request
  ///
  /// * [int] limit:
  ///   How many entries to return per page
  Future<GetAgents200Response?> getAgents({
    int? page,
    int? limit,
  }) async {
    final response = await getAgentsWithHttpInfo(
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
        'GetAgents200Response',
      ) as GetAgents200Response;
    }
    return null;
  }

  /// Get Agent
  ///
  /// Fetch your agent's details.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMyAgentWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/my/agent';

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

  /// Get Agent
  ///
  /// Fetch your agent's details.
  Future<GetMyAgent200Response?> getMyAgent() async {
    final response = await getMyAgentWithHttpInfo();
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
        'GetMyAgent200Response',
      ) as GetMyAgent200Response;
    }
    return null;
  }
}
