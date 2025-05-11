//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ApiClient {
  ApiClient({
    this.basePath = 'https://api.spacetraders.io/v2',
    this.authentication,
  });

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType,
  ) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty
        ? '?${urlEncodedQueryParams.join('&')}'
        : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (body is MultipartFile &&
          (contentType == null ||
              !contentType.toLowerCase().startsWith('multipart/form-data'))) {
        final request = StreamedRequest(method, uri);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
              request.sink.add,
              onDone: request.sink.close,
              // ignore: avoid_types_on_closure_parameters
              onError: (Object error, StackTrace trace) => request.sink.close(),
              cancelOnError: true,
            );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request = MultipartRequest(method, uri);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
          ? formParams
          : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      switch (method) {
        case 'POST':
          return await _client.post(
            uri,
            headers: nullableHeaderParams,
            body: msgBody,
          );
        case 'PUT':
          return await _client.put(
            uri,
            headers: nullableHeaderParams,
            body: msgBody,
          );
        case 'DELETE':
          return await _client.delete(
            uri,
            headers: nullableHeaderParams,
            body: msgBody,
          );
        case 'PATCH':
          return await _client.patch(
            uri,
            headers: nullableHeaderParams,
            body: msgBody,
          );
        case 'HEAD':
          return await _client.head(
            uri,
            headers: nullableHeaderParams,
          );
        case 'GET':
          return await _client.get(
            uri,
            headers: nullableHeaderParams,
          );
      }
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }

    throw ApiException(
      HttpStatus.badRequest,
      'Invalid HTTP operation: $method $path',
    );
  }

  Future<dynamic> deserializeAsync(
    String value,
    String targetType, {
    bool growable = false,
  }) async =>
      // ignore: deprecated_member_use_from_same_package
      deserialize(value, targetType, growable: growable);

  @Deprecated(
      'Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(
    String value,
    String targetType, {
    bool growable = false,
  }) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType =
        targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
        ? value
        : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated(
      'Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(
    dynamic value,
    String targetType, {
    bool growable = false,
  }) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'AcceptContract200Response':
          return AcceptContract200Response.fromJson(value);
        case 'AcceptContract200ResponseData':
          return AcceptContract200ResponseData.fromJson(value);
        case 'ActivityLevel':
          return ActivityLevelTypeTransformer().decode(value);
        case 'Agent':
          return Agent.fromJson(value);
        case 'AgentEvent':
          return AgentEvent.fromJson(value);
        case 'Chart':
          return Chart.fromJson(value);
        case 'ChartTransaction':
          return ChartTransaction.fromJson(value);
        case 'Construction':
          return Construction.fromJson(value);
        case 'ConstructionMaterial':
          return ConstructionMaterial.fromJson(value);
        case 'Contract':
          return Contract.fromJson(value);
        case 'ContractDeliverGood':
          return ContractDeliverGood.fromJson(value);
        case 'ContractPayment':
          return ContractPayment.fromJson(value);
        case 'ContractTerms':
          return ContractTerms.fromJson(value);
        case 'Cooldown':
          return Cooldown.fromJson(value);
        case 'CreateChart201Response':
          return CreateChart201Response.fromJson(value);
        case 'CreateChart201ResponseData':
          return CreateChart201ResponseData.fromJson(value);
        case 'CreateShipShipScan201Response':
          return CreateShipShipScan201Response.fromJson(value);
        case 'CreateShipShipScan201ResponseData':
          return CreateShipShipScan201ResponseData.fromJson(value);
        case 'CreateShipSystemScan201Response':
          return CreateShipSystemScan201Response.fromJson(value);
        case 'CreateShipSystemScan201ResponseData':
          return CreateShipSystemScan201ResponseData.fromJson(value);
        case 'CreateShipWaypointScan201Response':
          return CreateShipWaypointScan201Response.fromJson(value);
        case 'CreateShipWaypointScan201ResponseData':
          return CreateShipWaypointScan201ResponseData.fromJson(value);
        case 'CreateSurvey201Response':
          return CreateSurvey201Response.fromJson(value);
        case 'CreateSurvey201ResponseData':
          return CreateSurvey201ResponseData.fromJson(value);
        case 'DeliverContract200Response':
          return DeliverContract200Response.fromJson(value);
        case 'DeliverContract200ResponseData':
          return DeliverContract200ResponseData.fromJson(value);
        case 'DeliverContractRequest':
          return DeliverContractRequest.fromJson(value);
        case 'DockShip200Response':
          return DockShip200Response.fromJson(value);
        case 'DockShip200ResponseData':
          return DockShip200ResponseData.fromJson(value);
        case 'ExtractResources201Response':
          return ExtractResources201Response.fromJson(value);
        case 'ExtractResources201ResponseData':
          return ExtractResources201ResponseData.fromJson(value);
        case 'Extraction':
          return Extraction.fromJson(value);
        case 'ExtractionYield':
          return ExtractionYield.fromJson(value);
        case 'Faction':
          return Faction.fromJson(value);
        case 'FactionSymbol':
          return FactionSymbolTypeTransformer().decode(value);
        case 'FactionTrait':
          return FactionTrait.fromJson(value);
        case 'FactionTraitSymbol':
          return FactionTraitSymbolTypeTransformer().decode(value);
        case 'FulfillContract200Response':
          return FulfillContract200Response.fromJson(value);
        case 'GetAgent200Response':
          return GetAgent200Response.fromJson(value);
        case 'GetAgents200Response':
          return GetAgents200Response.fromJson(value);
        case 'GetConstruction200Response':
          return GetConstruction200Response.fromJson(value);
        case 'GetContract200Response':
          return GetContract200Response.fromJson(value);
        case 'GetContracts200Response':
          return GetContracts200Response.fromJson(value);
        case 'GetFaction200Response':
          return GetFaction200Response.fromJson(value);
        case 'GetFactions200Response':
          return GetFactions200Response.fromJson(value);
        case 'GetJumpGate200Response':
          return GetJumpGate200Response.fromJson(value);
        case 'GetMarket200Response':
          return GetMarket200Response.fromJson(value);
        case 'GetMounts200Response':
          return GetMounts200Response.fromJson(value);
        case 'GetMyAccount200Response':
          return GetMyAccount200Response.fromJson(value);
        case 'GetMyAccount200ResponseData':
          return GetMyAccount200ResponseData.fromJson(value);
        case 'GetMyAccount200ResponseDataAccount':
          return GetMyAccount200ResponseDataAccount.fromJson(value);
        case 'GetMyAgent200Response':
          return GetMyAgent200Response.fromJson(value);
        case 'GetMyAgentEvents200Response':
          return GetMyAgentEvents200Response.fromJson(value);
        case 'GetMyFactions200Response':
          return GetMyFactions200Response.fromJson(value);
        case 'GetMyFactions200ResponseDataInner':
          return GetMyFactions200ResponseDataInner.fromJson(value);
        case 'GetMyShip200Response':
          return GetMyShip200Response.fromJson(value);
        case 'GetMyShipCargo200Response':
          return GetMyShipCargo200Response.fromJson(value);
        case 'GetMyShips200Response':
          return GetMyShips200Response.fromJson(value);
        case 'GetRepairShip200Response':
          return GetRepairShip200Response.fromJson(value);
        case 'GetRepairShip200ResponseData':
          return GetRepairShip200ResponseData.fromJson(value);
        case 'GetScrapShip200Response':
          return GetScrapShip200Response.fromJson(value);
        case 'GetScrapShip200ResponseData':
          return GetScrapShip200ResponseData.fromJson(value);
        case 'GetShipCooldown200Response':
          return GetShipCooldown200Response.fromJson(value);
        case 'GetShipModules200Response':
          return GetShipModules200Response.fromJson(value);
        case 'GetShipNav200Response':
          return GetShipNav200Response.fromJson(value);
        case 'GetShipyard200Response':
          return GetShipyard200Response.fromJson(value);
        case 'GetStatus200Response':
          return GetStatus200Response.fromJson(value);
        case 'GetStatus200ResponseAnnouncementsInner':
          return GetStatus200ResponseAnnouncementsInner.fromJson(value);
        case 'GetStatus200ResponseLeaderboards':
          return GetStatus200ResponseLeaderboards.fromJson(value);
        case 'GetStatus200ResponseLeaderboardsMostCreditsInner':
          return GetStatus200ResponseLeaderboardsMostCreditsInner.fromJson(
              value);
        case 'GetStatus200ResponseLeaderboardsMostSubmittedChartsInner':
          return GetStatus200ResponseLeaderboardsMostSubmittedChartsInner
              .fromJson(value);
        case 'GetStatus200ResponseLinksInner':
          return GetStatus200ResponseLinksInner.fromJson(value);
        case 'GetStatus200ResponseServerResets':
          return GetStatus200ResponseServerResets.fromJson(value);
        case 'GetStatus200ResponseStats':
          return GetStatus200ResponseStats.fromJson(value);
        case 'GetSupplyChain200Response':
          return GetSupplyChain200Response.fromJson(value);
        case 'GetSupplyChain200ResponseData':
          return GetSupplyChain200ResponseData.fromJson(value);
        case 'GetSystem200Response':
          return GetSystem200Response.fromJson(value);
        case 'GetSystemWaypoints200Response':
          return GetSystemWaypoints200Response.fromJson(value);
        case 'GetSystems200Response':
          return GetSystems200Response.fromJson(value);
        case 'GetWaypoint200Response':
          return GetWaypoint200Response.fromJson(value);
        case 'InstallMount201Response':
          return InstallMount201Response.fromJson(value);
        case 'InstallMount201ResponseData':
          return InstallMount201ResponseData.fromJson(value);
        case 'InstallMountRequest':
          return InstallMountRequest.fromJson(value);
        case 'InstallShipModule201Response':
          return InstallShipModule201Response.fromJson(value);
        case 'InstallShipModule201ResponseData':
          return InstallShipModule201ResponseData.fromJson(value);
        case 'InstallShipModuleRequest':
          return InstallShipModuleRequest.fromJson(value);
        case 'Jettison200Response':
          return Jettison200Response.fromJson(value);
        case 'Jettison200ResponseData':
          return Jettison200ResponseData.fromJson(value);
        case 'JettisonRequest':
          return JettisonRequest.fromJson(value);
        case 'JumpGate':
          return JumpGate.fromJson(value);
        case 'JumpShip200Response':
          return JumpShip200Response.fromJson(value);
        case 'JumpShip200ResponseData':
          return JumpShip200ResponseData.fromJson(value);
        case 'JumpShipRequest':
          return JumpShipRequest.fromJson(value);
        case 'Market':
          return Market.fromJson(value);
        case 'MarketTradeGood':
          return MarketTradeGood.fromJson(value);
        case 'MarketTransaction':
          return MarketTransaction.fromJson(value);
        case 'Meta':
          return Meta.fromJson(value);
        case 'NavigateShip200Response':
          return NavigateShip200Response.fromJson(value);
        case 'NavigateShip200ResponseData':
          return NavigateShip200ResponseData.fromJson(value);
        case 'NavigateShipRequest':
          return NavigateShipRequest.fromJson(value);
        case 'NegotiateContract201Response':
          return NegotiateContract201Response.fromJson(value);
        case 'NegotiateContract201ResponseData':
          return NegotiateContract201ResponseData.fromJson(value);
        case 'OrbitShip200Response':
          return OrbitShip200Response.fromJson(value);
        case 'PatchShipNav200Response':
          return PatchShipNav200Response.fromJson(value);
        case 'PatchShipNavRequest':
          return PatchShipNavRequest.fromJson(value);
        case 'PublicAgent':
          return PublicAgent.fromJson(value);
        case 'PurchaseCargo201Response':
          return PurchaseCargo201Response.fromJson(value);
        case 'PurchaseCargo201ResponseData':
          return PurchaseCargo201ResponseData.fromJson(value);
        case 'PurchaseCargoRequest':
          return PurchaseCargoRequest.fromJson(value);
        case 'PurchaseShip201Response':
          return PurchaseShip201Response.fromJson(value);
        case 'PurchaseShip201ResponseData':
          return PurchaseShip201ResponseData.fromJson(value);
        case 'PurchaseShipRequest':
          return PurchaseShipRequest.fromJson(value);
        case 'RefuelShip200Response':
          return RefuelShip200Response.fromJson(value);
        case 'RefuelShip200ResponseData':
          return RefuelShip200ResponseData.fromJson(value);
        case 'RefuelShipRequest':
          return RefuelShipRequest.fromJson(value);
        case 'Register201Response':
          return Register201Response.fromJson(value);
        case 'Register201ResponseData':
          return Register201ResponseData.fromJson(value);
        case 'RegisterRequest':
          return RegisterRequest.fromJson(value);
        case 'RemoveMount201Response':
          return RemoveMount201Response.fromJson(value);
        case 'RemoveMount201ResponseData':
          return RemoveMount201ResponseData.fromJson(value);
        case 'RemoveMountRequest':
          return RemoveMountRequest.fromJson(value);
        case 'RemoveShipModule201Response':
          return RemoveShipModule201Response.fromJson(value);
        case 'RemoveShipModuleRequest':
          return RemoveShipModuleRequest.fromJson(value);
        case 'RepairShip200Response':
          return RepairShip200Response.fromJson(value);
        case 'RepairShip200ResponseData':
          return RepairShip200ResponseData.fromJson(value);
        case 'RepairTransaction':
          return RepairTransaction.fromJson(value);
        case 'ScannedShip':
          return ScannedShip.fromJson(value);
        case 'ScannedShipEngine':
          return ScannedShipEngine.fromJson(value);
        case 'ScannedShipFrame':
          return ScannedShipFrame.fromJson(value);
        case 'ScannedShipMountsInner':
          return ScannedShipMountsInner.fromJson(value);
        case 'ScannedShipReactor':
          return ScannedShipReactor.fromJson(value);
        case 'ScannedSystem':
          return ScannedSystem.fromJson(value);
        case 'ScannedWaypoint':
          return ScannedWaypoint.fromJson(value);
        case 'ScrapShip200Response':
          return ScrapShip200Response.fromJson(value);
        case 'ScrapShip200ResponseData':
          return ScrapShip200ResponseData.fromJson(value);
        case 'ScrapTransaction':
          return ScrapTransaction.fromJson(value);
        case 'SellCargo201Response':
          return SellCargo201Response.fromJson(value);
        case 'SellCargoRequest':
          return SellCargoRequest.fromJson(value);
        case 'Ship':
          return Ship.fromJson(value);
        case 'ShipCargo':
          return ShipCargo.fromJson(value);
        case 'ShipCargoItem':
          return ShipCargoItem.fromJson(value);
        case 'ShipConditionEvent':
          return ShipConditionEvent.fromJson(value);
        case 'ShipCrew':
          return ShipCrew.fromJson(value);
        case 'ShipEngine':
          return ShipEngine.fromJson(value);
        case 'ShipFrame':
          return ShipFrame.fromJson(value);
        case 'ShipFuel':
          return ShipFuel.fromJson(value);
        case 'ShipFuelConsumed':
          return ShipFuelConsumed.fromJson(value);
        case 'ShipModificationTransaction':
          return ShipModificationTransaction.fromJson(value);
        case 'ShipModule':
          return ShipModule.fromJson(value);
        case 'ShipMount':
          return ShipMount.fromJson(value);
        case 'ShipNav':
          return ShipNav.fromJson(value);
        case 'ShipNavFlightMode':
          return ShipNavFlightModeTypeTransformer().decode(value);
        case 'ShipNavRoute':
          return ShipNavRoute.fromJson(value);
        case 'ShipNavRouteWaypoint':
          return ShipNavRouteWaypoint.fromJson(value);
        case 'ShipNavStatus':
          return ShipNavStatusTypeTransformer().decode(value);
        case 'ShipReactor':
          return ShipReactor.fromJson(value);
        case 'ShipRefine201Response':
          return ShipRefine201Response.fromJson(value);
        case 'ShipRefine201ResponseData':
          return ShipRefine201ResponseData.fromJson(value);
        case 'ShipRefine201ResponseDataProducedInner':
          return ShipRefine201ResponseDataProducedInner.fromJson(value);
        case 'ShipRefineRequest':
          return ShipRefineRequest.fromJson(value);
        case 'ShipRegistration':
          return ShipRegistration.fromJson(value);
        case 'ShipRequirements':
          return ShipRequirements.fromJson(value);
        case 'ShipRole':
          return ShipRoleTypeTransformer().decode(value);
        case 'ShipType':
          return ShipTypeTypeTransformer().decode(value);
        case 'Shipyard':
          return Shipyard.fromJson(value);
        case 'ShipyardShip':
          return ShipyardShip.fromJson(value);
        case 'ShipyardShipCrew':
          return ShipyardShipCrew.fromJson(value);
        case 'ShipyardShipTypesInner':
          return ShipyardShipTypesInner.fromJson(value);
        case 'ShipyardTransaction':
          return ShipyardTransaction.fromJson(value);
        case 'Siphon':
          return Siphon.fromJson(value);
        case 'SiphonResources201Response':
          return SiphonResources201Response.fromJson(value);
        case 'SiphonResources201ResponseData':
          return SiphonResources201ResponseData.fromJson(value);
        case 'SiphonYield':
          return SiphonYield.fromJson(value);
        case 'SupplyConstruction201Response':
          return SupplyConstruction201Response.fromJson(value);
        case 'SupplyConstruction201ResponseData':
          return SupplyConstruction201ResponseData.fromJson(value);
        case 'SupplyConstructionRequest':
          return SupplyConstructionRequest.fromJson(value);
        case 'SupplyLevel':
          return SupplyLevelTypeTransformer().decode(value);
        case 'Survey':
          return Survey.fromJson(value);
        case 'SurveyDeposit':
          return SurveyDeposit.fromJson(value);
        case 'SurveySize':
          return SurveySizeTypeTransformer().decode(value);
        case 'System':
          return System.fromJson(value);
        case 'SystemFaction':
          return SystemFaction.fromJson(value);
        case 'SystemType':
          return SystemTypeTypeTransformer().decode(value);
        case 'SystemWaypoint':
          return SystemWaypoint.fromJson(value);
        case 'TradeGood':
          return TradeGood.fromJson(value);
        case 'TradeSymbol':
          return TradeSymbolTypeTransformer().decode(value);
        case 'TransferCargo200Response':
          return TransferCargo200Response.fromJson(value);
        case 'TransferCargo200ResponseData':
          return TransferCargo200ResponseData.fromJson(value);
        case 'TransferCargoRequest':
          return TransferCargoRequest.fromJson(value);
        case 'Waypoint':
          return Waypoint.fromJson(value);
        case 'WaypointFaction':
          return WaypointFaction.fromJson(value);
        case 'WaypointModifier':
          return WaypointModifier.fromJson(value);
        case 'WaypointModifierSymbol':
          return WaypointModifierSymbolTypeTransformer().decode(value);
        case 'WaypointOrbital':
          return WaypointOrbital.fromJson(value);
        case 'WaypointTrait':
          return WaypointTrait.fromJson(value);
        case 'WaypointTraitSymbol':
          return WaypointTraitSymbolTypeTransformer().decode(value);
        case 'WaypointType':
          return WaypointTypeTypeTransformer().decode(value);
        default:
          dynamic match;
          if (value is List &&
              (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
                .map<dynamic>((dynamic v) => fromJson(
                      v,
                      match,
                      growable: growable,
                    ))
                .toList(growable: growable);
          }
          if (value is Set &&
              (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
                .map<dynamic>((dynamic v) => fromJson(
                      v,
                      match,
                      growable: growable,
                    ))
                .toSet();
          }
          if (value is Map &&
              (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(
                    v,
                    match,
                    growable: growable,
                  )),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.internalServerError,
        'Exception during deserialization.',
        error,
        trace,
      );
    }
    throw ApiException(
      HttpStatus.internalServerError,
      'Could not find a suitable class for deserialization',
    );
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String' ? message.json : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
      ? message.json
      : ApiClient.fromJson(
          json.decode(message.json),
          targetType,
          growable: message.growable,
        );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async =>
    value == null ? '' : json.encode(value);
