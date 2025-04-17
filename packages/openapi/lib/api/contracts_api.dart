//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ContractsApi {
  ContractsApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Accept Contract
  ///
  /// Accept a contract by ID.   You can only accept contracts that were offered to you, were not accepted yet, and whose deadlines has not passed yet.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] contractId (required):
  ///   The contract ID to accept.
  Future<Response> acceptContractWithHttpInfo(
    String contractId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/my/contracts/{contractId}/accept'
        .replaceAll('{contractId}', contractId);

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

  /// Accept Contract
  ///
  /// Accept a contract by ID.   You can only accept contracts that were offered to you, were not accepted yet, and whose deadlines has not passed yet.
  ///
  /// Parameters:
  ///
  /// * [String] contractId (required):
  ///   The contract ID to accept.
  Future<AcceptContract200Response?> acceptContract(
    String contractId,
  ) async {
    final response = await acceptContractWithHttpInfo(
      contractId,
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
        'AcceptContract200Response',
      ) as AcceptContract200Response;
    }
    return null;
  }

  /// Deliver Cargo to Contract
  ///
  /// Deliver cargo to a contract.  In order to use this API, a ship must be at the delivery location (denoted in the delivery terms as `destinationSymbol` of a contract) and must have a number of units of a good required by this contract in its cargo.  Cargo that was delivered will be removed from the ship's cargo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] contractId (required):
  ///   The ID of the contract.
  ///
  /// * [DeliverContractRequest] deliverContractRequest:
  ///
  Future<Response> deliverContractWithHttpInfo(
    String contractId, {
    DeliverContractRequest? deliverContractRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/contracts/{contractId}/deliver'
        .replaceAll('{contractId}', contractId);

    // ignore: prefer_final_locals
    Object? postBody = deliverContractRequest;

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

  /// Deliver Cargo to Contract
  ///
  /// Deliver cargo to a contract.  In order to use this API, a ship must be at the delivery location (denoted in the delivery terms as `destinationSymbol` of a contract) and must have a number of units of a good required by this contract in its cargo.  Cargo that was delivered will be removed from the ship's cargo.
  ///
  /// Parameters:
  ///
  /// * [String] contractId (required):
  ///   The ID of the contract.
  ///
  /// * [DeliverContractRequest] deliverContractRequest:
  ///
  Future<DeliverContract200Response?> deliverContract(
    String contractId, {
    DeliverContractRequest? deliverContractRequest,
  }) async {
    final response = await deliverContractWithHttpInfo(
      contractId,
      deliverContractRequest: deliverContractRequest,
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
        'DeliverContract200Response',
      ) as DeliverContract200Response;
    }
    return null;
  }

  /// Fulfill Contract
  ///
  /// Fulfill a contract. Can only be used on contracts that have all of their delivery terms fulfilled.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] contractId (required):
  ///   The ID of the contract to fulfill.
  Future<Response> fulfillContractWithHttpInfo(
    String contractId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/my/contracts/{contractId}/fulfill'
        .replaceAll('{contractId}', contractId);

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

  /// Fulfill Contract
  ///
  /// Fulfill a contract. Can only be used on contracts that have all of their delivery terms fulfilled.
  ///
  /// Parameters:
  ///
  /// * [String] contractId (required):
  ///   The ID of the contract to fulfill.
  Future<FulfillContract200Response?> fulfillContract(
    String contractId,
  ) async {
    final response = await fulfillContractWithHttpInfo(
      contractId,
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
        'FulfillContract200Response',
      ) as FulfillContract200Response;
    }
    return null;
  }

  /// Get Contract
  ///
  /// Get the details of a contract by ID.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] contractId (required):
  ///   The contract ID
  Future<Response> getContractWithHttpInfo(
    String contractId,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/my/contracts/{contractId}'.replaceAll('{contractId}', contractId);

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

  /// Get Contract
  ///
  /// Get the details of a contract by ID.
  ///
  /// Parameters:
  ///
  /// * [String] contractId (required):
  ///   The contract ID
  Future<GetContract200Response?> getContract(
    String contractId,
  ) async {
    final response = await getContractWithHttpInfo(
      contractId,
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
        'GetContract200Response',
      ) as GetContract200Response;
    }
    return null;
  }

  /// List Contracts
  ///
  /// Return a paginated list of all your contracts.
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
  Future<Response> getContractsWithHttpInfo({
    int? page,
    int? limit,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/my/contracts';

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

  /// List Contracts
  ///
  /// Return a paginated list of all your contracts.
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///   What entry offset to request
  ///
  /// * [int] limit:
  ///   How many entries to return per page
  Future<GetContracts200Response?> getContracts({
    int? page,
    int? limit,
  }) async {
    final response = await getContractsWithHttpInfo(
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
        'GetContracts200Response',
      ) as GetContracts200Response;
    }
    return null;
  }
}
