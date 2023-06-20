[![codecov](https://codecov.io/gh/eseidel/space_traders/branch/main/graph/badge.svg?token=YU4WO0ULKW)](https://codecov.io/gh/eseidel/space_traders)

# Space Traders in Dart

Playing around with writing a Dart implementation of the Space Traders game.


## Usage

```
cd packages/space_traders_cli
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
* run `dart run bin/reset.dart`
* Update open_api_config.yaml to have the latest git hash.
* regenerate space_traders_api

### Generating `space_traders_api` package
```
dart pub global activate openapi_generator_cli
rmdir packages/space_traders_api/
openapi-generator generate -c open_api_config.yaml
```
Then modified:
* rmdir packages/space_traders_api/test directory since it was just TODOs.
* Fixed handling of required num fields:
    * `api/lib/model/jump_gate.dart`
  Due to: https://github.com/OpenAPITools/openapi-generator/pull/10637#pullrequestreview-1425351014
* Ran `dart format` on the generated code.

### Todo

Earning:
* Keep per-ship logs, so can calculate per-ship efficiency.
* Compute earnings per hour per ship.
* Fix arbitrage trader to be able to buy more than 10 units of low volume goods.
  The contract trader already knows how to do this?
* Fix miners to know how to travel to nearby markets to sell.
* Fix miners to know when to leave a system (when prices are too low).
* Track and print expected vs. actual profit on trades.
* Teach arbitrage trader how to empty its cargo hold of things it's not trading.
  If the markets it happens by don't trade those things it's stuck with them.
* Add logic for buying and mounting modules.
* Fix contract trader to not assume it's current market is the right one to buy
  from if the contract is fulfill-able from the market it's at.

Exploring:
* Probes should plan jumps based on distance to hq, not current location.
* Fix probes getting stuck cycling.
* Teach explorers to avoid each other.  Right now they all route to the same
  opportunities.
  Explorers should generate a queue of good systems to explore, and then
  pull from that queue?
* Explorers should explore an entire system and then go to the jumpgate
  and then from the jump gate plan their next system.

Tech Debt:
* Build a docker container and run the app in the cloud.  With a docker volume
  so the state persists.
* Get above 50% coverage.
* Fix all uses of DateTime.now() to be DateTime.timestamp() and test.

Efficiency:
* Start to build a system database similar to the pricing database.
* Persist some of WaypointCache to disk.
* Make dart run .\bin\percentage_mapped.dart -v make zero requests.
* Fix contract trader to share code with arbitrage trader.  Contracts are a
  special case of arbitrage, in which the destination and trade good are fixed.
* Add some object to hold agent and ships so both can be updated by results
  of API calls and not fetched after every ship.
* Write a better rate-limiting model.
* Teach RateLimiter to print out requests per minute every minute.

Automation:
* Automate resets
* Add a mass-move command which uses explore logic and logicLoop to move
  multiple ships at once.
* Have a config language to explain what mounts a ship should have.
* Have a config language to explain what the ships should be doing.
* Need to store handle and email somewhere.
* Need logic for planning which faction to be (random)?
* Ensure we don't join a faction which is not connected to others.
* Logic for planning what to do with money (e.g. buy ships, by mods)
  Should disable buying behavior for less time early on?
* When to enable which behaviors?
* Surveys.  How much surveying should we do before we start mining?

UI:
* Make shipInfo include an emoji for the behavior.
* Add a Flutter UI.
* Make it possible to filter for a sub-set of systems (e.g. ones with a market and a mine).

Thoughts
* Miners are just the "find me where to sell this" problem
* Contracts are just the "find me where to buy this" problem
* Arbitrage is both of those problems, should be able to share code.