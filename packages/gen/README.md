[![codecov](https://codecov.io/gh/eseidel/space_gen/graph/badge.svg?token=nOnPSYpPXi)](https://codecov.io/gh/eseidel/space_gen)

# space_gen
Simple, hackable Open API generator for Dart

This is not designed to be a full implementation of OpenAPI.  Currently
just enough to generate beautiful Dart bindings for spacetraders.io.

Patches welcome to expand it to support a wider set of OpenAPI.

## Usage

dart run space_gen

## Values
* Generates good quality, modern Dart code.
* Gives readable errors on failure.
* Generates much, but not all, of OpenAPI 3.0.
* Generates testable code.

## Design
* Parses the Spec, including recording JSON pointer locations and inferring model names.
* Resolves all references and loads resulting urls in the cache.
* Walks the parsed spec and renders to files using templates.

## Todo
* Generate tests. https://github.com/eseidel/space_gen/issues/1
* Handle min/max in newtype types.
* Wire up Authentication and sending of bearer header.
* GetSupplyChain200ResponseDataExportToImportMap is unnecessary?
* Simplify hasAdditionalProperties.
* Handle dynamic better (e.g. RefuelShipRequest.fromCargo)
* Confirm it's using the network proxy still (I don't think it is).
* Split Body from Query Parameters.
* Fix query parameters:
```
idle-1    | Unhandled exception:
idle-1    | type 'int' is not a subtype of type 'Iterable<dynamic>'
idle-1    | #0      _Uri._makeQueryFromParametersDefault.<anonymous closure> (dart:core/uri.dart:2521)
idle-1    | #1      _LinkedHashMapMixin.forEach (dart:_compact_hash:764)
idle-1    | #2      _Uri._makeQueryFromParametersDefault (dart:core/uri.dart:2517)
idle-1    | #3      _Uri._makeQueryFromParameters (dart:core-patch/uri_patch.dart:88)
idle-1    | #4      _Uri._makeQuery (dart:core/uri.dart:2490)
idle-1    | #5      _SimpleUri.replace (dart:core/uri.dart:4483)
idle-1    | #6      ApiClient.invokeApi (package:openapi/api_client.dart:36)
idle-1    | #7      CountingApiClient.invokeApi (package:cli/net/counts.dart:23)
idle-1    | #8      SystemsApi.getSystems (package:openapi/api/systems_api.dart:26)
idle-1    | #9      allSystems.<anonymous closure> (package:cli/net/queries.dart:30)
idle-1    | #10     fetchAllPages (package:cli/net/queries.dart:17)
```

## Advantages over Open API Generator 7.0.0
* Dart 3.0+ only (sound null safety)
* Model code round trips through JSON correctly (TBD)
* Generates properly recursive toJson/fromJson which round-trip fully!
* Able to generate immutable models.
* Uses real enum classes!
* fromJson is non-nullable.
* Generates maybeFromJson with explicit nullability.
* Generates independent classes, which can be imported independently.
* Better follows required vs. nullable semantics.

## Why not just contribute to OpenAPI?

As of August 2023, there are two separate (soon to be combined?) OpenAPI
generators for Dart.  One for package:http and one for package:dio.  I only
ever used the http one and it had lots of bugs.  I looked at fixing them
in OpenAPI, but failed to figure out how to hack on the OpenAPI generator
(Java) or successfully interact with the community (several separate slacks).


### OpenApi Quirks

space_gen implements a few OpenAPI quirks to optionally make the generated
output maximally openapi_generator compatible in case you're transitioning
from openapi_generator to space_gen.

#### Lists default to []

OpenAPI makes all List values default to [], and stores all lists as
non-nullable, even if they're nullable (not required) in the spec.  This
breaks round-tripping of values, since if your 'list' property is null
(or missing) openapi_generator will parse it as [] and send back [].  The
openapi_generator can never send null for a list value.