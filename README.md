# Space Traders in Flutter

Playing around with writing a Flutter implementation of the Space Traders game.

This is not the first one, I know of at least one other:
https://crucknuk.itch.io/space-traders
But I've not seen the source for that and it appears to be v1 rather than v2.


## Generating `api` package
```
dart pub global activate openapi_generator_cli
openapi-generator generate -c open_api_config.yaml
```