[![codecov](https://codecov.io/gh/eseidel/space_traders/branch/main/graph/badge.svg?token=YU4WO0ULKW)](https://codecov.io/gh/eseidel/space_traders)

# Space Traders in Dart

Playing around with writing a Dart implementation of the Space Traders game.


## Usage

```
cd packages/cli
dart run
```

Example output:

```
 dart run
Building package executable... (1.6s)
Built space_traders_cli:space_traders_cli.
Welcome to Space Traders! 🚀
🛸#1 ⛏️   6 COPPER_ORE         📦 57/60
🛸#2 ⛏️   3 AMMONIA_ICE        📦 17/30
🛸#1 Docking at X1-VS75-67965Z
🛸#1 🤝  6 COPPER_ORE         -14%  -8c per,  6 x  48c = +288c -> 🏦 30,624c
🛸#1 🤝  6 ICE_WATER          -13%  -2c per,  6 x  13c =  +78c -> 🏦 30,702c
🛸#1 🤝 12 QUARTZ_SAND        👌 per, 12 x  21c = +252c -> 🏦 30,954c
🛸#1 🤝  7 IRON_ORE           +52%  13c per,  7 x  38c = +266c -> 🏦 31,220c
🛸#1 🤝 11 ALUMINUM_ORE        -6%  -3c per, 11 x  48c = +528c -> 🏦 31,748c
⏱️ 62s until 2023-05-20 10:25:38.984
🛸#1 Moving to orbit at X1-VS75-67965Z
🛸#1 ⛏️   6 QUARTZ_SAND        📦 21/60
🛸#2 ⛏️   5 ICE_WATER          📦 22/30
⏱️ 66s until 2023-05-20 10:26:52.461
🛸#1 ⛏️   8 AMMONIA_ICE        📦 29/60
🛸#2 ⛏️   8 AMMONIA_ICE        📦 30/30
🛸#2 Docking at X1-VS75-67965Z
🛸#2 🤝 11 ICE_WATER          -13%  -2c per, 11 x  13c = +143c -> 🏦 31,891c
🛸#2 🤝 11 AMMONIA_ICE         -5%  -2c per, 11 x  40c = +440c -> 🏦 32,331c
🛸#2 🤝  8 SILICON_CRYSTALS   -14%  -5c per,  8 x  31c = +248c -> 🏦 32,579c
⏱️ 63s until 2023-05-20 10:28:05.339
🛸#1 ⛏️   4 ICE_WATER          📦 33/60
🛸#2 Moving to orbit at X1-VS75-67965Z
🛸#2 ⛏️   5 AMMONIA_ICE        📦  5/30
⏱️ 65s until 2023-05-20 10:29:18.158
🛸#1 ⛏️   8 SILICON_CRYSTALS   📦 41/60
🛸#2 ⛏️   6 COPPER_ORE         📦 11/30
⏱️ 66s until 2023-05-20 10:30:31.109
🛸#1 ⛏️   4 ICE_WATER          📦 45/60
🛸#2 ⛏️   7 COPPER_ORE         📦 18/30
⏱️ 66s until 2023-05-20 10:31:43.985
```

## Other Dart Clients

The only other one I've seen is: https://crucknuk.itch.io/space-traders
But I've not seen the source for that and it appears to be v1 rather than v2.

### Bugs to report to OpenAPI
* Required arguments in request body should make body required/non-nullable.
  Example: RegisterRequest for POST /users/register
* The generated "enums" do not have equals or hashCode.  e.g. ShipRole.
  It doesn't end up mattering because they're singletons though.
* Generated toJson methods are not recursive (e.g. Survey.toJson doesn't call
  SurveyDeposit.toJson).

## Development

## Reset day checklist
* run `dart run bin/reset.dart` -- does not work.
* Update open_api_config.yaml to have the latest git hash.
* regenerate space_traders_api

### Generating `space_traders_api` package
```
dart pub global activate openapi_generator_cli
rmdir packages/openapi/
openapi-generator generate -c open_api_config.yaml
```
Then modified:
* `rmdir packages/openapi/test` directory since it was just TODOs.
* Fixed handling of required num fields:
    * `packages/openapi/lib/model/jump_gate.dart`
  Due to: https://github.com/OpenAPITools/openapi-generator/pull/10637#pullrequestreview-1425351014
* Ran `dart format packages/openapi`

### Todo

Earning:
* Keep per-ship logs, so can calculate per-ship efficiency.
* Use recent earnings-per-second in ship behavior planning.
* Fix miners to know how to travel to nearby markets to sell.
* Fix miners to know when to leave a system (when prices are too low).
* Add logic for buying and mounting modules.
* Traders only consider how repeated buys inflate prices, they do not consider
  how repeated sells might deflate prices at sell point.
* Teach miners how to coordinate with haulers to sell their goods further away.
* Add refining
* Add gas siphoning
* Add logic for command ship to switch between trading and mining depending
  on expected profit.
* Record trade volume on a per-market basis in pricing data.
* Buy traders when trading is more profitable than mining, and vice versa.
* Dead ships aren't differnet from idle ships and will be counted as
  "idle haulers" and prevent buying more ships.
* Remove all use of maxJumps and use distance or maxWaypoints instead.
* Be able to buy miners outside of the main system.
* Be able to support miners across multiple systems.
* Be able to move miners between systems.

Exploring:
* Explorers should explore an entire system and then go to the jump gate
  and then from the jump gate plan their next system.
* Probes should go sit at shipyards and marketplaces when there is nothing
  to explore.
* Buy an Explorer and teach it how to warp to other systems and other
  jump gate clusters.

Tech Debt:
* Fix all uses of DateTime.now() to be DateTime.timestamp() and test.
* Write a test suite for routing.
* Make all load/loadCached functions consistent.

Efficiency:
* Make dart run .\bin\percentage_mapped.dart -v make zero requests.
* Write a better rate-limiting model.
* Make the script robust to network failures.
* Teach route planner how to warp.

Automation:
* Have a config language to explain what mounts a ship should have.
* Have a config language to explain what the ships should be doing.
* Need to store handle and email somewhere.
* Need logic for planning which faction to be (random)?
* Logic for planning what to do with money (e.g. buy ships, by mods)
  Should disable buying behavior for less time early on?
* Surveys.  How much surveying should we do before we start mining?
* Add the ability to "queue" behaviors, so that when a ship pulls its next
  behavior it can pull from the queue.  This would allow us to queue a buyShip
  for a ship which was otherwise busy at the moment, for example?

UI:
* Make shipInfo include an emoji for the behavior.
* Add a Flutter UI.
* Make it possible to filter for a sub-set of systems (e.g. ones with a market and a mine).
* Show where all ships currently are.
* Show which waypoints are charted vs. not.
* Show which systems have a market vs. not.
* Show which systems have a mine vs. not.
* Show which systems have a shipyard vs. not.
* Show which systems have a jump gate vs. not.

Thoughts
* Miners are just the "find me where to sell this" problem
* Contracts are just the "find me where to buy this" problem
* Arbitrage is both of those problems, should be able to share code.


### Handle 500 errors better:

🛸#20 ✈️  to X1-AP26-80647B, 00:00:00 left
[WARN] Failed to parse exception json: FormatException: Unexpected character (at line 2, character 1)
<html><head>
^

[WARN] Failed to parse exception json: FormatException: Unexpected character (at line 2, character 1)
<html><head>
^

Unhandled exception:
ApiException 500:
<html><head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<title>500 Server Error</title>
</head>
<body text=#000000 bgcolor=#ffffff>
<h1>Error: Server Error</h1>
<h2>The server encountered an error and could not complete your request.<p>Please try again in 30 seconds.</h2>
<h2></h2>
</body></html>

#0      SystemsApi.getSystemWaypoints (package:openapi/api/systems_api.dart:394:7)
<asynchronous suspension>


### Automatically handle resets:
ApiException 401: {"error":{"message":"Failed to parse token. Token reset_date does not match the server. Server resets happen on a weekly to bi-weekly frequency during alpha. After a reset, you should re-register your agent. Expected: 2023-07-08, Actual: 2023-06-24","code":401,"data":{"expected":"2023-07-08","actual":"2023-06-24"}}}



[WARN] Failed to parse exception json: FormatException: Unexpected character (at character 1)
HTTP connection failed: POST /my/ships/ESEIDEL-15/navigate
^

Unhandled exception:
ApiException 400: HTTP connection failed: POST /my/ships/ESEIDEL-15/navigate (Inner exception: Connection reset by peer)

#0      IOClient.send (package:http/src/io_client.dart:96:7)
<asynchronous suspension>
#1      BaseClient._sendUnstreamed (package:http/src/base_client.dart:93:32)
<asynchronous suspension>
#2      ApiClient.invokeAPI (package:openapi/api_client.dart:101:18)
<asynchronous suspension>
#3      RateLimitedApiClient.handleUnexpectedRateLimit (package:cli/net/rate_limit.dart:63:24)
<asynchronous suspension>
#4      RateLimitedApiClient.invokeAPI (package:cli/net/rate_limit.dart:101:22)
<asynchronous suspension>
#5      FleetApi.navigateShip (package:openapi/api/fleet_api.dart:1189:22)
<asynchronous suspension>
#6      navigateShip (package:cli/net/direct.dart:53:7)
<asynchronous suspension>


### Server is returning ship inventories with an unstable sort:
Ship list differs at index 2: [differs at offset 3046:, ... "symbol":"ALUMINUM_O ..., ... "symbol":"PRECIOUS_S ...,               ^]
[WARN] Ship list changed, updating cache.

### Filter by accounting type rather than FUEL:
🛸#10 🤝 120 FUEL                 +7%  +8c per 120 x    126c = +15,120c -> 🏦 214,830c
[WARN] 🛸#10 Expected 480c profit (16c/s), got 15,120c (397c/s) in 00:00:38, expected 00:00:30

### Jump timing:
[WARN] 🛸#A  Jump X1-U93 to X1-KV19 (1759) expected 176, got 175.
[WARN] 🛸#4C Jump X1-UM11 to X1-SY37 (2000) expected 200, got 199.

### Explorer double shipyard record?
🛸#1A ✈️  to X1-VQ83-56254F, -8ms left
🛸#1A 🗺️  X1-VQ83-56254F - ORBITAL_STATION - Research Facility, Industrial, Marketplace, Shipyard
🛸#1A ✍️  market data @ X1-VQ83-56254F
🛸#1A ✍️  shipyard data @ X1-VQ83-56254F
🛸#1A ✍️  shipyard data @ X1-VQ83-56254F
🛸#1A X1-BB5-41700X is missing chart, routing.

### Sell side trade volumes killing profits

🛸#C  ✍️  shipyard data @ X1-XD55-07827C
🛸#C  🤝  10 MODULE_ORE_REFINERY_I   +4% +824c per  10 x 23,237c = +232,370c -> 🏦 10,806,100c
🛸#C  🤝  10 MODULE_ORE_REFINERY_I   +3% +601c per  10 x 23,014c = +230,140c -> 🏦 11,036,240c
🛸#C  🤝  10 MODULE_ORE_REFINERY_I   +1% +327c per  10 x 22,740c = +227,400c -> 🏦 11,263,640c
🛸#C  🤝  10 MODULE_ORE_REFINERY_I    0% -10c per  10 x 22,403c = +224,030c -> 🏦 11,487,670c
🛸#C  🤝  10 MODULE_ORE_REFINERY_I   -2% -425c per  10 x 21,988c = +219,880c -> 🏦 11,707,550c
🛸#C  🤝  10 MODULE_ORE_REFINERY_I   -4% -937c per  10 x 21,476c = +214,760c -> 🏦 11,922,310c
🛸#C  🤝  10 MODULE_ORE_REFINERY_I   -7% -1,566c per  10 x 20,847c = +208,470c -> 🏦 12,130,780c
[WARN] 🛸#C  Expected 121,552c profit (220c/s), got -14,130c (-21c/s) in 00:10:49, expected 00:09:12

### Some routes take way too long:
[WARN] planning X1-MZ67-89424A to X1-ZC22-26502F took 27s
[WARN] planning X1-QY7-49849C to X1-ZC22-26502F took 1m
[WARN] planning X1-QZ16-60787C to X1-ZC22-26502F took 15s
[WARN] planning X1-PR89-34810A to X1-ZC22-26502F took 13s
[WARN] planning X1-YP31-34280X to X1-VS61-13110B took 4s

### Ships chasing each other
🛸#4B ✈️  to X1-TM59-47122Z, 7m left
🛸#4C ✈️  to X1-TM59-47122Z, 7m left
🛸#4D ✈️  to X1-PQ90-95787D, -1m left
🛸#4E ✈️  to X1-PQ90-95787D, -1m left
🛸#4F ✈️  to X1-TM59-47122Z, 7m left
🛸#50 ✈️  to X1-TM59-47122Z, 7m left
🛸#54 ✈️  to X1-TM59-47122Z, 7m left
🛸#55 ✈️  to X1-TM59-47122Z, 7m left
🛸#56 ✈️  to X1-TM59-47122Z, 7m left
🛸#57 ✈️  to X1-TM59-47122Z, 7m left