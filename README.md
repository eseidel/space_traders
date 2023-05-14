# Space Traders in Dart

Playing around with writing a Dart implementation of the Space Traders game.

This is not the first one, I know of at least one other:
https://crucknuk.itch.io/space-traders
But I've not seen the source for that and it appears to be v1 rather than v2.


## Usage

```
cd packages/space_traders_cli
dart run
```

## Development

### Generating `api` package
```
dart pub global activate openapi_generator_cli
openapi-generator generate -c open_api_config.yaml
```

### Todo

Logic:
* Use the survey when mining from the command ship.
* Record surveys to be used by vessels at the same location.
* Record prices seen in systems
* Teach the command ship how to mine
* Once have a list of prices try to find arbitrage opportunities
* Compute earnings per hour per ship.

UI:
* Add a Flutter UI.

### Modifications to generated code

* Removed tests/ directory since it was just TODOs.
* Fixed handling of required num fields in two places:
    * `api/lib/model/jump_gate.dart`
    * `api/lib/model/ship_engine.dart`
  Due to: https://github.com/OpenAPITools/openapi-generator/pull/10637#pullrequestreview-1425351014


### Bugs to report to OpenAPI
* required arguments in a request body should make the body required/non-nullable.
  Example: RegisterRequest for POST /users/register
* The generated "enums" do not have equals or hashCode.  e.g. ShipRole.
  It doesn't end up mattering because they're singletons though.