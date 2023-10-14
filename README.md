[![codecov](https://codecov.io/gh/eseidel/space_traders/branch/main/graph/badge.svg?token=YU4WO0ULKW)](https://codecov.io/gh/eseidel/space_traders)

# Space Traders in Dart

Playing around with writing a Dart implementation of the Space Traders game.

## Setup

This requires Dart 3.0.0 or later.

The easiest way to get Dart is typically via Flutter.  See
https://flutter.dev/docs/get-started/install for instructions.

On ubuntu:
```
sudo snap install flutter --classic
```

If you're running this in a docker container, or otherwise as root Dart and
Flutter will print a warning about running as root.  You can ignore it or
disable it with:
```
export BOT=true
```

## Contents
* packages/cli - A command line interface to the Space Traders API.
* packages/openapi - A generated Dart client for the Space Traders API.
* packages/server - A very basic server for supporting the UI.
* packages/ui - A Flutter UI for the Space Traders API.

packages/cli is the only package that is well developed.  openapi is generated
and the rest are in very early stages of development.

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

### Bugs to report to OpenAPI
* Required arguments in request body should make body required/non-nullable.
  Example: RegisterRequest for POST /users/register
* The generated "enums" do not have equals or hashCode.  e.g. ShipRole.
  It doesn't end up mattering because they're singletons though.
* Generated toJson methods are not recursive (e.g. Survey.toJson doesn't call
  SurveyDeposit.toJson).

## Development

## Reset day checklist
* run `cd packages/cli`, `dart run bin/reset.dart`
* run `cd packages/db`, `docker exec spacetraders_postgres /scripts/init_db.sh spacetraders`
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

Most impact:
* Make saving take less time (log rolling or db?), also avoids dataloss.
* Could await on sometime other than the network (e.g. a priority queue).
* Add atomic writes (write to a temp file and then rename).

To sort:
* Add a "storage" behavior to have a place to put unused mounts.
* Make it easier to re-spec miners mid cycle (without throwing away mounts).
* Record requests per-ship?  Calculate number of requests used per cycle?
* Simulate refining
* Simulate gas siphoning
* Teach Haulers how to pick up from miners.
* Add mounts to survey results (so we can compute diamond frequency).
* Compute survey frequency per-trade symbol.
* Confirm survey sizes have consistent extraction rates across trade symbols.
* Share code between MarketPrices and ShipyardPrices.

Earning:
* Keep per-ship logs, so can calculate per-ship efficiency.
* Use recent earnings-per-second in ship behavior planning.
* Fix miners to know when to leave a system (when prices are too low).
* Teach miners how to coordinate with haulers to sell their goods further away.
* Add refining
* Add gas siphoning
* Buy traders when trading is more profitable than mining, and vice versa.
* Remove all use of maxJumps and use distance or maxWaypoints instead.
  Jumps will get the wrong answers in dense areas of the galaxy.
* Be able to buy miners outside of the main system.
* Calculate "wait time" when servicing a ship.
* Try changing deal finding heuristic to only consider buy price.
* Spread out traders across the galaxy better.
* buy-in-a-loop for small tradeVolumes gets worse as we have more ships.
  This is likely the #1 contributor to "wait time".
  Every place we return null to loop has the same problem.
* Record which ship generated a survey?
* Allow ships to buy from the same location at high trade volumes?
* Have one thread be generating instructions and another thread executing.
  When execution hits an error, just throw it back to the generator thread.
  Run each of the ships as separate "programs".
  Unclear if multi-threaded will work OK with json files.
* Make Survey selection find a value point and then look back further than
  the last 100 surveys for surveys above that value.
* Print warnings when our predicted buy/sell price differs from actual.
* Do we correctly navigate right away after the last jump?
* Use the closest ship to a shipyard when buying a ship.

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
* Need to store handle and email somewhere.
* Need logic for planning which faction to be (random)?
* Logic for planning what to do with money (e.g. buy ships, by mods)
  Should disable buying behavior for less time early on?
* Surveys.  How much surveying should we do before we start mining?

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


[WARN] 🛸#C  took 1s (2 requests) expected 0.7s
[WARN] 🛸#C  (miner) took 1s (2 requests) expected 0.7s
Unhandled exception:
ApiException 500: {"error":{"code":500,"message":"Something unexpected went wrong! If you want to help you can file an issue here: https://github.com/SpaceTradersAPI/api-docs"}}
#0      FleetApi.sellCargo (package:openapi/api/fleet_api.dart:1762:7)
<asynchronous suspension>
#1      sellCargo (package:cli/net/direct.dart:121:7)
<asynchronous suspension>
#2      sellAllCargo (package:cli/net/actions.dart:79:24)
<asynchronous suspension>
#3      sellAllCargoAndLog (package:cli/net/actions.dart:110:3)
<asynchronous suspension>
#4      advanceMiner (package:cli/behavior/miner.dart:215:7)
<asynchronous suspension>
#5      advanceShipBehavior (package:cli/behavior/advance.dart:83:23)
<asynchronous suspension>
#6      advanceShips (package:cli/logic.dart:51:25)
<asynchronous suspension>
#7      logic (package:cli/logic.dart:150:7)
<asynchronous suspension>
#8      cliMain (file:///root/space_traders/packages/cli/bin/cli.dart:101:3)
<asynchronous suspension>
#9      main.<anonymous closure> (file:///root/space_traders/packages/cli/bin/cli.dart:107:7)
<asynchronous suspension>
#10     main (file:///root/space_traders/packages/cli/bin/cli.dart:105:3)
<asynchronous suspension>

### Server is returning ship inventories with an unstable sort:
Ship list differs at index 2: [differs at offset 3046:, ... "symbol":"ALUMINUM_O ..., ... "symbol":"PRECIOUS_S ...,               ^]
[WARN] Ship list changed, updating cache.

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

### Deal planning needs a cache
🛸#4A ✍️  market data @ X1-AF63-69302X
[WARN] 🛸#4A No profitable deals within 10 jumps of X1-AF63.
[WARN] planning X1-QC19-44545C to X1-FK85-17613A took 3s
[WARN] Costed 15 deals in 3s
[WARN] planning X1-ZK61-40889A to X1-FK85-17613A took 2s
[WARN] Costed 5 deals in 2s
[WARN] planning X1-HA27-82906A to X1-FK85-17613A took 3s
[WARN] Costed 2 deals in 3s
[WARN] planning X1-VP50-40413C to X1-FK85-17613A took 6s
[WARN] planning X1-RQ52-75611B to X1-FK85-17613A took 8s
[WARN] Costed 5 deals in 15s
[WARN] planning X1-NK41-26588X to X1-FK85-17613A took 8s
[WARN] Costed 8 deals in 8s
[WARN] planning X1-BS76-95937C to X1-FK85-17613A took 3s
[WARN] Costed 10 deals in 3s
[WARN] planning X1-Y3-22546F to X1-FK85-17613A took 4s
[WARN] Costed 2 deals in 4s
[WARN] planning X1-JX18-24605A to X1-FK85-17613A took 5s
[WARN] Costed 6 deals in 5s
[WARN] planning X1-CX61-59010D to X1-FK85-17613A took 3s
[WARN] Costed 5 deals in 3s
[WARN] Costed 2 deals in 1s
[WARN] planning X1-MA9-83012X to X1-FK85-17613A took 5s
[WARN] Costed 12 deals in 5s
[WARN] Costed 57 deals in 1s
[WARN] Costed 4 deals in 1s
[WARN] planning X1-VF21-68037Z to X1-FK85-17613A took 4s
[WARN] Costed 6 deals in 4s
[WARN] planning X1-YA66-57211X to X1-FK85-17613A took 2s
[WARN] Costed 4 deals in 2s
[WARN] Costed 18 deals in 1s
[WARN] planning X1-NS34-07355A to X1-FK85-17613A took 10s
[WARN] Costed 39 deals in 11s
[WARN] Costed 64 deals in 1s
[WARN] planning X1-UB97-84299A to X1-FK85-17613A took 2s
[WARN] Costed 12 deals in 3s
[WARN] Costed 4 deals in 1s
[WARN] planning X1-VF43-91464B to X1-FK85-17613A took 2s
[WARN] Costed 8 deals in 2s
[WARN] Costed 10 deals in 1s
[WARN] Costed 81 deals in 1s
🛸#4A Found placement: 7c/s 9820 35449 X1-UZ93-16812Z
🛸#4A Potential: COPPER_ORE                 X1-YP31-30465Z      35c -> X1-YP31-21892B      55c     +20c (57%) 314s 7c/s 4,322c
🛸#4A Beginning route to X1-UZ93-16812Z
🛸#4A 🛫 to X1-AF63-64525B JUMP_GATE (2m) spent 104 fuel
[WARN] 🛸#4A (trader) took 124s (3 requests) expected 1.0s


### Bad jump if ship cache is stale?
ApiException 400: {"error":{"message":"Failed to execute jump. Ship cannot execute jump to the system it is currently located in.","code":4208}}
#0      FleetApi.jumpShip (package:openapi/api/fleet_api.dart:1118:7)


<title>500 Server Error</title>
</head>
<body text=#000000 bgcolor=#ffffff>
<h1>Error: Server Error</h1>
<h2>The server encountered an error and could not complete your request.<p>Please try again in 30 seconds.</h2>
<h2></h2>
</body></html>
, retrying after 1 seconds
Unhandled exception:
ApiException 400: {"error":{"message":"Failed to execute jump. Ship cannot execute jump to the system it is currently located in.","code":4208}}
#0      FleetApi.jumpShip (package:openapi/api/fleet_api.dart:1118:7)


### Does the trader know how to complete contracts that don't require moving?
deliver 1210  COPPER_ORE to X1-FA31-74322Z in 6d for 161,510c with 32,985c upfront
Expected profit: 125,525c

### Crashed due to 500

🛸#3B ✍️  market data @ X1-UK74-29935F
🛸#3B ⛽   4 FUEL                           ⚖️    4 x    122c =   -488c -> 🏦 12,239,210c
Unhandled exception:
ApiException 500: {"error":{"code":500,"message":"Something unexpected went wrong! If you want to help you can file an issue here: https://github.com/SpaceTradersAPI/api-docs"}}
#0      SystemsApi.getShipyard (package:openapi/api/systems_api.dart:235:7)
<asynchronous suspension>
#1      getShipyard (package:cli/net/queries.dart:55:20)
<asynchronous suspension>
#2      CentralCommand.visitLocalShipyard (package:cli/behavior/central_command.dart:826:22)
<asynchronous suspension>
#3      advanceTrader (package:cli/behavior/trader.dart:512:3)
<asynchronous suspension>
#4      advanceShips (package:cli/logic.dart:36:25)
<asynchronous suspension>
#5      logic (package:cli/logic.dart:128:7)
<asynchronous suspension>
#6      cliMain (file:///root/space_traders/packages/cli/bin/cli.dart:79:3)
<asynchronous suspension>
#7      main.<anonymous closure> (file:///root/space_traders/packages/cli/bin/cli.dart:85:7)
<asynchronous suspension>
#8      main (file:///root/space_traders/packages/cli/bin/cli.dart:83:3)
<asynchronous suspension>

And another:

Unhandled exception:
ApiException 500: {"error":{"code":500,"message":"Something unexpected went wrong! If you want to help you can file an issue here: https://github.com/SpaceTradersAPI/api-docs"}}
#0      FleetApi.purchaseCargo (package:openapi/api/fleet_api.dart:1476:7)
<asynchronous suspension>
#1      purchaseCargo (package:cli/net/direct.dart:143:7)
<asynchronous suspension>
#2      purchaseCargoAndLog (package:cli/net/actions.dart:140:18)
<asynchronous suspension>
#3      purchaseTradeGoodIfPossible (package:cli/behavior/trader.dart:82:18)
<asynchronous suspension>
#4      _handleAtSourceWithDeal (package:cli/behavior/trader.dart:129:25)
<asynchronous suspension>
#5      advanceTrader (package:cli/behavior/trader.dart:680:23)
<asynchronous suspension>
#6      advanceShipBehavior (package:cli/behavior/advance.dart:83:23)
<asynchronous suspension>
#7      advanceShips (package:cli/logic.dart:51:25)
<asynchronous suspension>
#8      logic (package:cli/logic.dart:150:7)
<asynchronous suspension>
#9      cliMain (file:///root/space_traders/packages/cli/bin/cli.dart:101:3)
<asynchronous suspension>
#10     main.<anonymous closure> (file:///root/space_traders/packages/cli/bin/cli.dart:107:7)
<asynchronous suspension>
#11     main (file:///root/space_traders/packages/cli/bin/cli.dart:105:3)

### Show how many more units we would by:
🛸#61 Purchased 10 of MODULE_CREW_QUARTERS_I, still have 10 units we would like to buy, looping.
🛸#61 Purchased 10 of MODULE_CREW_QUARTERS_I, still have 10 units we would like to buy, looping.
🛸#61 Purchased 10 of MODULE_CREW_QUARTERS_I, still have 10 units we would like to buy, looping.
🛸#61 Purchased 10 of MODULE_CREW_QUARTERS_I, still have 10 units we would like to buy, looping.


### Make sure multiple ships can work on a single contract:
deliver 96000 (95640 remaining) ALUMINUM_ORE to X1-ST5-23902F in 6d for 6,182,400c with 2,649,600c upfront
Expected profit: 3,840,000c

Maybe show the list of ships on it in the output?


### Prevent bad trades?

🛸#2B ✈️  to X1-PY78-88810Z, -2s left
🛸#2B ✍️  market data @ X1-PY78-88810Z
🛸#2B ⛽   2 FUEL                           ⚖️    2 x    122c =   -244c -> 🏦 2,632,986c
🛸#2B 🤝 100 MACHINERY            +2% +11c per 100 x    576c = +57,600c -> 🏦 2,690,586c
🛸#2B 🤝  10 MACHINERY            +0%  +1c per  10 x    566c = +5,660c -> 🏦 2,696,246c
🛸#2B Expected 3,174c profit (7c/s), got -2,830c (-6c/s) in 00:07:20, expected 00:07:01

### Our handling is still wrong:

🛸#27 ✈️  to X1-MN97-71751A, -3s left
🛸#27 ✍️  market data @ X1-MN97-71751A
🛸#27 ⛽   6 FUEL                           ⚖️    6 x    122c =   -732c -> 🏦 2,726,894c
🛸#27 💸  10 MACHINERY           -56% -642c per  10 x    498c = -4,980c -> 🏦 2,721,914c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MACHINERY           -55% -627c per  10 x    513c = -5,130c -> 🏦 2,716,784c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MACHINERY           -53% -608c per  10 x    532c = -5,320c -> 🏦 2,711,464c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MACHINERY           -51% -585c per  10 x    555c = -5,550c -> 🏦 2,705,914c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MACHINERY           -49% -557c per  10 x    583c = -5,830c -> 🏦 2,700,084c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MACHINERY           -46% -522c per  10 x    618c = -6,180c -> 🏦 2,693,904c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MACHINERY           -42% -478c per  10 x    662c = -6,620c -> 🏦 2,687,284c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MACHINERY           -37% -425c per  10 x    715c = -7,150c -> 🏦 2,680,134c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MACHINERY           -32% -360c per  10 x    780c = -7,800c -> 🏦 2,672,334c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MACHINERY           -25% -280c per  10 x    860c = -8,600c -> 🏦 2,663,734c
🛸#27 Purchased 10 of MACHINERY, still have 10 units we would like to buy, looping.
🛸#27 ✍️  market data @ X1-MN97-71751A
🛸#27 MACHINERY is too expensive at X1-MN97-71751A needed < 573, got 959
🛸#27 Beginning route to X1-NG76-74133A
🛸#27 🛫 to X1-MN97-97114E JUMP_GATE (1m) spent 43 fuel


🛸#27 ✈️  to X1-XY58-42132Z, -5s left
🛸#27 ✍️  market data @ X1-XY58-42132Z
🛸#27 ⛽   3 FUEL                           ⚖️    3 x    122c =   -366c -> 🏦 7,293,930c
🛸#27 💸  10 MICROPROCESSORS     -56% -750c per  10 x    600c = -6,000c -> 🏦 7,287,930c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MICROPROCESSORS     -55% -737c per  10 x    613c = -6,130c -> 🏦 7,281,800c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MICROPROCESSORS     -53% -721c per  10 x    629c = -6,290c -> 🏦 7,275,510c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MICROPROCESSORS     -52% -701c per  10 x    649c = -6,490c -> 🏦 7,269,020c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MICROPROCESSORS     -50% -677c per  10 x    673c = -6,730c -> 🏦 7,262,290c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MICROPROCESSORS     -48% -647c per  10 x    703c = -7,030c -> 🏦 7,255,260c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MICROPROCESSORS     -45% -610c per  10 x    740c = -7,400c -> 🏦 7,247,860c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MICROPROCESSORS     -42% -565c per  10 x    785c = -7,850c -> 🏦 7,240,010c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MICROPROCESSORS     -38% -509c per  10 x    841c = -8,410c -> 🏦 7,231,600c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 💸  10 MICROPROCESSORS     -33% -441c per  10 x    909c = -9,090c -> 🏦 7,222,510c
🛸#27 Purchased 10 of MICROPROCESSORS, still have 10 units we would like to buy, looping.
🛸#27 ✍️  market data @ X1-XY58-42132Z
🛸#27 MICROPROCESSORS is too expensive at X1-XY58-42132Z needed < 662, got 994
🛸#27 Beginning route to X1-QQ30-77574B

### Print more debugging information about why trades fail?

🛸#42 ✈️  to X1-QZ69-30211C, -1ms left
🛸#42 ✍️  market data @ X1-QZ69-30211C
🛸#42 ⛽   3 FUEL                           ⚖️    3 x    122c =   -366c -> 🏦 7,181,528c
🛸#42 🤝 100 LAB_INSTRUMENTS      +1%  +5c per 100 x    695c = +69,500c -> 🏦 7,251,028c
🛸#42 Expected 6,350c profit (8c/s), got -5,740c (-7c/s) in 00:12:51, expected 00:12:10
[WARN] 🛸#42 No profitable deals within 10 jumps of X1-QZ69.

e.g. did the price change since when the trade was scoped vs. when it was executed?


### Confirm System.json validity against /stats
"The /status endpoint also gives you the total number of entities in the stats node. You could compare against that and retrigger the download."
```
{
  "stats": {
    "agents": 199,
    "ships": 1757,
    "systems": 12000,
    "waypoints": 66798
  }
}
```

## Confused

🛸#54 🛫 to X1-UC71-90215B JUMP_GATE (39s) spent 49 fuel
🛸#6F ✈️  to X1-YA22-87615D, -1m left
Unhandled exception:
Invalid argument (marketSymbol): ESEIDEL-6F is not at X1-YA22-87615D, X1-YA22-92610F.: Instance of 'WaypointSymbol'
#0      recordMarketDataIfNeededAndLog (package:cli/cache/market_prices.dart:468:5)
#1      visitLocalMarket (package:cli/behavior/explorer.dart:65:24)
<asynchronous suspension>
#2      advanceTrader (package:cli/behavior/trader.dart:643:25)
<asynchronous suspension>
#3      advanceShipBehavior (package:cli/behavior/advance.dart:83:23)
<asynchronous suspension>
#4      advanceShips (package:cli/logic.dart:51:25)
<asynchronous suspension>
#5      logic (package:cli/logic.dart:150:7)
<asynchronous suspension>
#6      cliMain (file:///root/space_traders/packages/cli/bin/cli.dart:101:3)
<asynchronous suspension>
#7      main.<anonymous closure> (file:///root/space_traders/packages/cli/bin/cli.dart:107:7)
<asynchronous suspension>
#8      main (file:///root/space_traders/packages/cli/bin/cli.dart:105:3)
<asynchronous suspension>

## Use best-place-to-buy logic for ships:
[WARN] 🛸#1  Can not buy SHIP_ORE_HOUND at X1-YA22-18767C, credits 318,996c < 1.05 * price = 1,334,568c. Disabling Behavior.buyShip for 10m.

## Teach late-start clients how to purchase traders instead of miners?

### Surveys
Miners will likely fight over surveys, probably all grabbing the "best"
survey and possibly exhausting it at the same time and having to restart
the mining operation?

### Add a /healthz cli and monitor it.

### Network Queue Exception?

🛸#54 ✍️  market data @ X1-TM41-05300A
Unhandled exception:
Bad state: No element
#0      Stream.firstWhere.<anonymous closure> (dart:async/stream.dart:1703:9)
#1      _rootRun (dart:async/zone.dart:1391:47)
#2      _CustomZone.run (dart:async/zone.dart:1301:19)
#3      _CustomZone.runGuarded (dart:async/zone.dart:1209:7)
#4      _BufferingStreamSubscription._sendDone.sendDone (dart:async/stream_impl.dart:392:13)
#5      _BufferingStreamSubscription._sendDone (dart:async/stream_impl.dart:402:7)
#6      _DelayedDone.perform (dart:async/stream_impl.dart:534:14)
#7      _PendingEvents.handleNext (dart:async/stream_impl.dart:620:11)
#8      _PendingEvents.schedule.<anonymous closure> (dart:async/stream_impl.dart:591:7)
#9      _rootRun (dart:async/zone.dart:1399:13)
#10     _CustomZone.run (dart:async/zone.dart:1301:19)
#11     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:1233:23)
#12     _microtaskLoop (dart:async/schedule_microtask.dart:40:21)
#13     _startMicrotaskLoop (dart:async/schedule_microtask.dart:49:5)
#14     _runPendingImmediateCallback (dart:isolate-patch/isolate_patch.dart:123:13)
#15     _RawReceivePort._handleMessage (dart:isolate-patch/isolate_patch.dart:190:5)

On both:

Unhandled exception:
Bad state: No element
#0      Stream.firstWhere.<anonymous closure> (dart:async/stream.dart:1703:9)
#1      _rootRun (dart:async/zone.dart:1391:47)
#2      _CustomZone.run (dart:async/zone.dart:1301:19)
#3      _CustomZone.runGuarded (dart:async/zone.dart:1209:7)
#4      _BufferingStreamSubscription._sendDone.sendDone (dart:async/stream_impl.dart:392:13)
#5      _BufferingStreamSubscription._sendDone (dart:async/stream_impl.dart:402:7)
#6      _DelayedDone.perform (dart:async/stream_impl.dart:534:14)
#7      _PendingEvents.handleNext (dart:async/stream_impl.dart:620:11)
#8      _PendingEvents.schedule.<anonymous closure> (dart:async/stream_impl.dart:591:7)
#9      _rootRun (dart:async/zone.dart:1399:13)
#10     _CustomZone.run (dart:async/zone.dart:1301:19)
#11     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:1233:23)
#12     _microtaskLoop (dart:async/schedule_microtask.dart:40:21)
#13     _startMicrotaskLoop (dart:async/schedule_microtask.dart:49:5)
#14     _runPendingImmediateCallback (dart:isolate-patch/isolate_patch.dart:123:13)

### Write a test for stability of the network queue.

### Teach network backoffs to have a limit (e.g. 128s).


### 500s should not take down the client.

🛸#6D Beginning route to X1-QH21-95970X
Unhandled exception:
ApiException 500: {"error":{"code":500,"message":"Something unexpected went wrong! If you want to help you can file an issue here: https://github.com/SpaceTradersAPI/api-docs"}}
#0      FleetApi.orbitShip (package:openapi/api/fleet_api.dart:1328:7)
<asynchronous suspension>
#1      undockIfNeeded (package:cli/net/actions.dart:315:22)
<asynchronous suspension>
#2      continueNavigationIfNeeded (package:cli/nav/navigation.dart:196:3)
<asynchronous suspension>
#3      beingRouteAndLog (package:cli/nav/navigation.dart:73:21)
<asynchronous suspension>
#4      beingNewRouteAndLog (package:cli/nav/navigation.dart:43:20)
<asynchronous suspension>
#5      advanceTrader (package:cli/behavior/trader.dart:706:23)
<asynchronous suspension>
#6      advanceShipBehavior (package:cli/behavior/advance.dart:88:23)
<asynchronous suspension>
#7      advanceShips (package:cli/logic.dart:52:25)
<asynchronous suspension>
#8      logic (package:cli/logic.dart:152:7)
<asynchronous suspension>
#9      cliMain (file:///root/space_traders/packages/cli/bin/cli.dart:106:3)
<asynchronous suspension>
#10     main.<anonymous closure> (file:///root/space_traders/packages/cli/bin/cli.dart:112:7)
<asynchronous suspension>
#11     main (file:///root/space_traders/packages/cli/bin/cli.dart:110:3)
<asynchronous suspension>

### Navigate error after network interrupt

ApiException 400: {"error":{"message":"Ship is currently in-transit from X1-MU55-23072X to X1-MU55-79315D and arrives in 19 seconds.","code":4214,"data":{"departureSymbol
":"X1-MU55-23072X","destinationSymbol":"X1-MU55-79315D","arrival":"2023-08-22T05:14:17.353Z","departureTime":"2023-08-22T05:13:49.353Z","secondsToArrival":19}}}
#0      FleetApi.navigateShip (package:openapi/api/fleet_api.dart:1194:7)
<asynchronous suspension>
#1      navigateShip (package:cli/net/direct.dart:58:7)
<asynchronous suspension>
#2      navigateToLocalWaypoint (package:cli/net/actions.dart:35:23)
<asynchronous suspension>
#3      navigateToLocalWaypointAndLog (package:cli/net/actions.dart:333:18)
<asynchronous suspension>
#4      continueNavigationIfNeeded (package:cli/nav/navigation.dart:219:11)
<asynchronous suspension>
#5      beingRouteAndLog (package:cli/nav/navigation.dart:76:21)
<asynchronous suspension>
#6      beingNewRouteAndLog (package:cli/nav/navigation.dart:44:20)
<asynchronous suspension>
#7      advanceTrader (package:cli/behavior/trader.dart:787:21)
<asynchronous suspension>
#8      advanceShipBehavior (package:cli/behavior/advance.dart:89:23)
<asynchronous suspension>
#9      advanceShips (package:cli/logic.dart:52:25)
<asynchronous suspension>
#10     logic (package:cli/logic.dart:152:7)
<asynchronous suspension>
#11     cliMain (file:///root/space_traders/packages/cli/bin/cli.dart:137:3)
<asynchronous suspension>
#12     main.<anonymous closure> (file:///root/space_traders/packages/cli/bin/cli.dart:143:7)
<asynchronous suspension>
#13     main (file:///root/space_traders/packages/cli/bin/cli.dart:141:3)
<asynchronous suspension>


### Buy first orehound immediately:

[WARN] 🛸#1  Can not buy SHIP_ORE_HOUND at X1-AG30-04017A, credits 150,000c < 1.05 * price = 167,932c. Disabling Behavior.buyShip for ESEIDEL-1 for 10m.
🛸#1  Deliver 0
[WARN] 🛸#1  No deliveries needed. Disabling Behavior.deliver for ESEIDEL-1 for 10m.
🛸#1  ✍️  market data @ X1-AG30-65570X
Accepted: deliver 1060  COPPER_ORE to X1-AG30-29102A in 6d for 160,272c with 34,344c upfront.
received 34,344c

### Wiring up hauling for miners

Somehow represent the miners in deals, producting a given tradeSymbol for
zero cost, at some amount of time to produce?


### No debugging tools for surveys.

Write a tool to list how many surveys deep we have?


### Optimize requests:

^CRequest stats:
6508 /my/ships/N/navigate
6323 /my/ships/N/dock
6322 /my/ships/N/orbit
5797 /my/ships/N/sell
5753 /my/ships/N/extract/survey
3118 /my/ships/N/refuel
2522 /systems/N/waypoints/N/market
1422 /my/ships/N/survey
756 /my/ships/N/jump
677 /my/ships/N/purchase
122 /systems/N/waypoints/N/shipyard
36 /my/ships
29 /systems/N/waypoints


### Use RefuelShipRequest to specify units to refuel.

Should just take the number of missing units and round down to the closest
hundred.


### Implement missing bits of SAF's strat

"At the start of a reset my miners sell themselves and only locally, after that
I add haulers to which the miners transfers the cargo and they sell locally or
nearby. currently running 20 surveyors, 50 extractors, 20 or so heavy freighter
haulers 30 backup light haulers and an army of probes trying to update markets
around the primary partition if there are requests left to spend."
https://discord.com/channels/792864705139048469/792864705139048472/1160644392185503774


### Survey EVs are 0 at the very beginning:
X1-DK86-91295E-BA7460 SMALL SILICON_CRYSTALS, IRON_ORE, ICE_WATER, ICE_WATER, ICE_WATER, PRECIOUS_STONES, ICE_WATER ev 0c
⏱️  1m until 2023-10-14 16:50:26.838
🛸#1  🔭 1x at X1-DK86-91295E
X1-DK86-91295E-78D652 SMALL PRECIOUS_STONES, ALUMINUM_ORE, ALUMINUM_ORE, COPPER_ORE ev 0c
⏱️  1m until 2023-10-14 16:51:36.927
🛸#1  🔭 1x at X1-DK86-91295E
X1-DK86-91295E-DC6E8D SMALL ICE_WATER, QUARTZ_SAND, AMMONIA_ICE, ICE_WATER ev 0c
⏱️  1m until 2023-10-14 16:52:47.013
🛸#1  🔭 1x at X1-DK86-91295E
X1-DK86-91295E-D0E02B SMALL ICE_WATER, ICE_WATER, SILICON_CRYSTALS, SILICON_CRYSTALS, SILICON_CRYSTALS ev 0c

# Mount buying and ship-buying compete at the beginning

🛸#6  Starting buy mount MOUNT_MINING_LASER_II
🛸#6  Beginning route to X1-DK86-32917D (1m)
🛸#6  🛫 to X1-DK86-32917D ORBITAL_STATION (1m) spent 68 fuel
🛸#2  ✈️  to X1-DB41-95854C, 1m left
🛸#5  ✍️  shipyard data @ X1-DK86-32917D
🛸#5  Purchased SHIP_ORE_HOUND for 165,220c -> 🏦 14,731c
🛸#5  Bought ship: ESEIDEL-B
[WARN] 🛸#5  Purchased ESEIDEL-B (SHIP_ORE_HOUND)! Disabling Behavior.buyShip for ESEIDEL-5 for 10m.
[WARN] Adding missing ship ESEIDEL-B