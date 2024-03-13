
### Todo

To sort:
* Record requests per-ship?  Calculate number of requests used per cycle?
* Confirm survey sizes have consistent extraction rates across trade symbols.
* Make shipInfo include an emoji for the behavior.

Earning:
* Keep per-ship logs, so can calculate per-ship efficiency.
* Use recent earnings-per-second in ship behavior planning.
* Be able to buy miners outside of the main system.
* Try changing deal finding heuristic to only consider buy price.
* Spread out traders across the galaxy better.
* Record which ship generated a survey and with what mounts?
* Allow ships to buy from the same location at high trade volumes?
* Make Survey selection find a value point and then look back further than
  the last 100 surveys for surveys above that value.
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
* Write a test suite for routing.

Efficiency:
* Make the script robust to network failures.
* Teach route planner how to warp.

Automation:
* Need to store handle and email somewhere.
* Need logic for planning which faction to be (random)?
* Logic for planning what to do with money (e.g. buy ships, by mods)
  Should disable buying behavior for less time early on?

Thoughts
* Miners are just the "find me where to sell this" problem
* Contracts are just the "find me where to buy this" problem
* Arbitrage is both of those problems, should be able to share code.

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

### Teach network back-offs to have a limit (e.g. 128s).

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

### No debugging tools for surveys.

Write a tool to list how many surveys deep we have?

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

### Mount buying and ship-buying compete at the beginning

🛸#6  Starting buy mount MOUNT_MINING_LASER_II
🛸#6  Beginning route to X1-DK86-32917D (1m)
🛸#6  🛫 to X1-DK86-32917D ORBITAL_STATION (1m) spent 68 fuel
🛸#2  ✈️  to X1-DB41-95854C, 1m left
🛸#5  ✍️  shipyard data @ X1-DK86-32917D
🛸#5  Purchased SHIP_ORE_HOUND for 165,220c -> 🏦 14,731c
🛸#5  Bought ship: ESEIDEL-B
[WARN] 🛸#5  Purchased ESEIDEL-B (SHIP_ORE_HOUND)! Disabling Behavior.buyShip for ESEIDEL-5 for 10m.
[WARN] Adding missing ship ESEIDEL-B

### Handshake exception brought down client.

Unhandled exception:
HandshakeException: Connection terminated during handshake

[WARN] Failed to parse exception json: FormatException: Unexpected character (at character 1)
Exception occurred: POST /my/ships/ESEIDEL-7/jump
^

Unhandled exception:
ApiException 400: Exception occurred: POST /my/ships/ESEIDEL-7/jump (Inner exception: TimeoutException after 0:00:30.000000: Future not completed)


#0      ApiClient.invokeAPI (package:openapi/api_client.dart:164:7)
<asynchronous suspension>
#1      FleetApi.jumpShip (package:openapi/api/fleet_api.dart:1187:22)
<asynchronous suspension>
#2      _useJumpGateAndLogInner (package:cli/net/actions.dart:409:7)
<asynchronous suspension>
#3      useJumpGateAndLog (package:cli/net/actions.dart:427:9)
<asynchronous suspension>
#4      continueNavigationIfNeeded (package:cli/nav/navigation.dart:222:11)
<asynchronous suspension>
#5      advanceShipBehavior (package:cli/behavior/advance.dart:74:17)
<asynchronous suspension>
#6      advanceShips (package:cli/logic.dart:71:29)

### Refuel less often.

### Change everything to support c/r in addition to c/s

* Create a new hauler behavior that sends haulers to mines to take goods.
* Teach Miners to decide whether to:
  * Sell local
  * Travel and sell
  * Transfer to a hauler
  * Jettison


### Add callback to RequestCounterApi and have it record requests in behavior.

### Avoid catastrophic trades

🛸#65 ✍️  shipyard data @ X1-ZP28-72377A
🛸#65 🤝   1 ENGINE_ION_DRIVE_II +107% +20,769c per   1 x 40,214c = +40,214c -> 🏦 287,136,414c
🛸#65 🤝   1 ENGINE_ION_DRIVE_II  +95% +18,415c per   1 x 37,860c = +37,860c -> 🏦 287,174,274c
🛸#65 🤝   1 ENGINE_ION_DRIVE_II  +80% +15,516c per   1 x 34,961c = +34,961c -> 🏦 287,209,235c
🛸#65 🤝   1 ENGINE_ION_DRIVE_II  +61% +11,948c per   1 x 31,393c = +31,393c -> 🏦 287,240,628c
🛸#65 🤝   1 ENGINE_ION_DRIVE_II  +39% +7,555c per   1 x 27,000c = +27,000c -> 🏦 287,267,628c
🛸#65 🤝   1 ENGINE_ION_DRIVE_II  +11% +2,146c per   1 x 21,591c = +21,591c -> 🏦 287,289,219c
🛸#65 🤝   1 ENGINE_ION_DRIVE_II  -23% -4,513c per   1 x 14,932c = +14,932c -> 🏦 287,304,151c
🛸#65 🤝   1 ENGINE_ION_DRIVE_II  -65% -12,712c per   1 x  6,733c = +6,733c -> 🏦 287,310,884c
🛸#65 🤝   1 ENGINE_ION_DRIVE_II -100% -19,444c per   1 x      1c =     +1c -> 🏦 287,310,885c
🛸#65 🤝   1 ENGINE_ION_DRIVE_II -100% -19,444c per   1 x      1c =     +1c -> 🏦 287,310,886c
🛸#65 Expected 18,669c profit (71c/s), got -147,134c (-311c/s) in 00:07:53, expected 00:04:22

If nothing else, each interval should be evaluted against the possibility of moving to sell?

### Log error rates from network executor

### Record minable traits with surveys

### Record surveyor type with surveys

### Remove MarketCache

### Divide Surveyors into squads and assign one squad per mine.

Once this is working can buy more of each.

### Add some sort of dynamic evaluation of the quality of a mine (every hour?)

### Keep per-ship action logs

### Be able to plan trades with less than full cargo.

e.g. 
SHIP_COMMAND_FRIGATE @ X1-QP91-B7, speed = 30 capacity = 60, fuel <= 1200, outlay <= 1000000, jumps <= 10, waypoints <= 200 
Opps for 51 trade symbols.
Top 100 deals:
MEDICINE                   X1-QP91-D47     12,505c -> X1-QP91-A1      16,664c +204,814c (27%) 3m 930c/s 770,456c
CLOTHING                   X1-QP91-K83     14,338c -> X1-QP91-A1      18,548c +201,726c (23%) 5m 663c/s 883,794c
MACHINERY                  X1-QP91-E50      1,968c -> X1-QP91-D48      2,459c  +25,055c (20%) 4m  90c/s 122,485c
ELECTRONICS                X1-QP91-F52      2,072c -> X1-QP91-A3       2,510c  +18,374c (14%) 3m  89c/s 128,576c
ELECTRONICS                X1-QP91-F52      2,072c -> X1-QP91-D47      2,455c  +18,425c (14%) 4m  76c/s 128,875c
ELECTRONICS                X1-QP91-F52      2,072c -> X1-QP91-D48      2,446c  +17,885c (14%) 4m  74c/s 128,875c
ELECTRONICS                X1-QP91-F52      2,072c -> X1-QP91-H56      2,439c  +14,224c (11%) 3m  64c/s 128,576c
MICROPROCESSORS            X1-QP91-A3       2,900c -> X1-QP91-D47      3,193c  +11,725c  (7%) 3m  49c/s 179,855c
ELECTRONICS                X1-QP91-F52      2,072c -> X1-QP91-C45      2,394c  +11,016c  (9%) 4m  37c/s 129,174c
EQUIPMENT                  X1-QP91-K83      2,516c -> X1-QP91-A1       2,854c  +10,586c  (7%) 5m  34c/s 156,514c
EQUIPMENT                  X1-QP91-K83      2,516c -> X1-QP91-D47      2,721c   +6,447c  (4%) 5m  18c/s 156,813c
GOLD                       X1-QP91-B6         266c -> X1-QP91-H58        332c   +2,464c (14%) 3m  13c/s  17,456c
SILVER                     X1-QP91-B6         231c -> X1-QP91-H58        277c   +1,264c  (8%) 3m   6c/s  15,356c
ALUMINUM                   X1-QP91-H55        161c -> X1-QP91-K83        202c     +815c  (7%) 4m   3c/s  11,305c

I should be able to do some partial trades of the high-value items for decent money.

### CostedDeal.limitUnitsByMaxSpend doesn't seem to fit under limit.

If you pass it 1000000, CostedDeal.expectedCosts will end up slightly
higher than that?


### Will unintentionally drift instead of routing to refuel.

I don't know if B6 sells fuel.  But it drifted when it should have refueled:

🛸#1  ✈️  to X1-QP91-B6, 0ms left
🛸#1  ✍️  market data @ X1-QP91-B6
🛸#1  🤝  10 FUEL               +158% +342c per  10 x    558c = +5,580c -> 🏦 3,855,281c
🛸#1  🤝  10 FUEL               +130% +281c per  10 x    497c = +4,970c -> 🏦 3,860,251c
🛸#1  🤝  10 FUEL               +106% +229c per  10 x    445c = +4,450c -> 🏦 3,864,701c
🛸#1  🤝   5 FUEL                +85% +183c per   5 x    399c = +1,995c -> 🏦 3,866,696c
[WARN] 🛸#1  Expected 9,542c profit (30c/s), got 9,255c (3c/s) in 00:45:06, expected 00:05:18
[WARN] 🛸#1  Beginning route to X1-QP91-A3 (4m)
[WARN] 🛸#1  Insufficient fuel, drifting to X1-QP91-A3
🛸#1  🛫 to X1-QP91-A3 MOON (45m) spent 1 fuel
[WARN] 🛸#1  Flight time 00:45:57 does not match predicted 00:45:56 speed: 30 mode: DRIFT distance: 328.9331239021087

% dart run bin/routing_plan.dart X1-QP91-B6 X1-QP91-A3
Route found (5ms)
X1-QP91-B6 to X1-QP91-A3 speed: 30 max-fuel: 1200
navCruise       X1-QP91-B6  X1-QP91-A3  0:04:49.000000s
in 4m uses 329 fuel


### Catastrophic trades

🛸#1  ✍️  shipyard data @ X1-QP91-C45
🛸#1  🤝  10 SHIP_PLATING        +33% +5,941c per  10 x 23,834c = +238,340c -> 🏦 905,407c
🛸#1  🤝  10 SHIP_PLATING        +19% +3,337c per  10 x 21,230c = +212,300c -> 🏦 1,117,707c
🛸#1  🤝  10 SHIP_PLATING         +1% +131c per  10 x 18,024c = +180,240c -> 🏦 1,297,947c
🛸#1  Expected 11,331c profit (52c/s), got -73,430c (-299c/s) in 00:04:05, expected 00:03:35


### Refactor sellAllCargo to only sell on lot at a time.

That way we can run our "where should we sell this" in between lots.

### Route planning is not aware of partial tanks of fuel.

If you don't have a full tank of fuel, it will plan a route that will
cause you to end up drifting, what it should do is plan an early refuel in it
and when it refuels re-set to a full capacity.

### Make sure construction handles completion correctly.

I'm not sure we have any guards for when construction is completed.

### Plan route through fails if the first leg eats all fuel.

e.g.
fuelCapacity: 100
A -> B = 100
B -> C = 1000 (so drift)
Try to plan [A, B, C] = fails but it should find a [DRIFT, DRIFT] route, or
if B has fuel, a [CRUISE, DRIFT] route.


### Can we plan better routes than this?

🛸#F  Starting: X1-QP91-H56 to X1-QP91-B11 speed: 3 max-fuel: 80
navCruise       X1-QP91-H56  X1-QP91-A3  0:06:38.000000s
refuel          X1-QP91-A3  X1-QP91-A3  0:00:00.000000s
navCruise       X1-QP91-A3  X1-QP91-F51  0:07:36.000000s
refuel          X1-QP91-F51  X1-QP91-F51  0:00:00.000000s
navDrift        X1-QP91-F51  X1-QP91-B11  6:16:38.000000s
in 6h uses 101 fuel

🛸#C  Starting: X1-QP91-H56 to X1-QP91-B13 speed: 3 max-fuel: 80
navCruise       X1-QP91-H56  X1-QP91-D48  0:06:13.000000s
refuel          X1-QP91-D48  X1-QP91-D48  0:00:00.000000s
navDrift        X1-QP91-D48  X1-QP91-B13  6:09:41.000000s
in 6h uses 45 fuel

🛸#D  Starting: X1-QP91-H56 to X1-QP91-B16 speed: 3 max-fuel: 80
navCruise       X1-QP91-H56  X1-QP91-A3  0:06:38.000000s
refuel          X1-QP91-A3  X1-QP91-A3  0:00:00.000000s
navCruise       X1-QP91-A3  X1-QP91-F51  0:07:36.000000s
refuel          X1-QP91-F51  X1-QP91-F51  0:00:00.000000s
navDrift        X1-QP91-F51  X1-QP91-B16  7:03:51.000000s
in 7h uses 101 fuel

🛸#E  Starting: X1-QP91-H56 to X1-QP91-B14 speed: 3 max-fuel: 80
navCruise       X1-QP91-H56  X1-QP91-D47  0:06:13.000000s
refuel          X1-QP91-D47  X1-QP91-D47  0:00:00.000000s
navDrift        X1-QP91-D47  X1-QP91-B14  5:54:25.000000s
in 6h uses 45 fuel

### Contract failure?

Unhandled exception:
ApiException 400: {"error":{"message":"Agent ESEIDEL already has an active contract.","code":4511,"data":{"agentSymbol":"ESEIDEL","contractId":"clon2tb9m00dqs60cmjrptyet"}}}
#0      FleetApi.negotiateContract (package:openapi/api/fleet_api.dart:1335:7)
<asynchronous suspension>
#1      negotiateContractAndLog (package:cli/net/actions.dart:502:20)
<asynchronous suspension>
#2      acceptContractsIfNeeded (package:cli/behavior/trader.dart:663:9)
<asynchronous suspension>
#3      advanceTrader (package:cli/behavior/trader.dart:843:5)
<asynchronous suspension>
#4      advanceShipBehavior (package:cli/behavior/advance.dart:101:23)
<asynchronous suspension>
#5      advanceShips (package:cli/logic.dart:71:29)
<asynchronous suspension>
#6      logic (package:cli/logic.dart:184:7)
<asynchronous suspension>
#7      cliMain (file:///root/space_traders/packages/cli/bin/cli.dart:148:3)
<asynchronous suspension>
#8      main.<anonymous closure> (file:///root/space_traders/packages/cli/bin/cli.dart:154:7)
<asynchronous suspension>
#9      main (file:///root/space_traders/packages/cli/bin/cli.dart:152:3)
<asynchronous suspension>

I think this happened due to time skew with the server during Contact expiration.

Our local check though the contract was expired.  But the server didn't.

# BuyShip job can race:

🛸#1  Purchased SHIP_LIGHT_SHUTTLE for 83,956c -> 🏦 260,176c
🛸#1  Bought ship: ESEIDEL-4
[WARN] 🛸#1  Purchased ESEIDEL-4 (SHIP_LIGHT_SHUTTLE)!
[WARN] Adding missing ship ESEIDEL-4
[WARN] FleetRole.unknown has no specified behaviors, idling.
🛸#1  ✍️  shipyard data @ X1-RK11-A2
🛸#1  Purchased SHIP_LIGHT_SHUTTLE for 88,259c -> 🏦 171,917c
🛸#1  Bought ship: ESEIDEL-5
[WARN] 🛸#1  Purchased ESEIDEL-5 (SHIP_LIGHT_SHUTTLE)!
[WARN] Adding missing ship ESEIDEL-5
[WARN] FleetRole.unknown has no specified behaviors, idling.

### Make MineSquad locations more dynamic

Should be possible with making scores more dynamic?

### Make Siphon Squads

### Remove auto-drifting.

Just clogs up trade routes.

ESEIDEL-4: Behavior.trader
  In transit to X1-RK11-I57 JUMP_GATE TRANSPORT trader 0/40
  destination: X1-RK11-E46, arrives in 5h
  ASSAULT_RIFLES             X1-RK11-E46      2,049c -> X1-RK11-J60      4,760c +104,594c (126%) 3h   9c/s  82,996c
 duration: 2h
ESEIDEL-5: Behavior.trader
  In transit to X1-RK11-I58 FUEL_STATION TRANSPORT trader 0/40
  destination: X1-RK11-D45, arrives in 3h
  ADVANCED_CIRCUITRY         X1-RK11-D45      2,801c -> X1-RK11-I57     13,000c +405,466c (354%) 2h  45c/s 114,534c
 duration: 2h

### Add Extraction validation logic

Validate extractableByMount, against what is actually extracted and
expectedGoodsForWaypoint against what is actually surveyed.

### Dies delivering construction materials:

Unhandled exception:
ApiException 400: {"error":{"message":"Construction material requirements for ADVANCED_CIRCUITRY have been met.","code":4801}}
#0      SystemsApi.supplyConstruction (package:openapi/api/systems_api.dart:742:7)
<asynchronous suspension>
#1      supplyConstruction (package:cli/net/direct.dart:153:20)
<asynchronous suspension>
#2      _deliverConstructionMaterialsIfPossible (package:cli/behavior/trader.dart:430:20)
<asynchronous suspension>
#3      _handleConstructionDealAtDelivery (package:cli/behavior/trader.dart:393:3)
<asynchronous suspension>
#4      MultiJob.run (package:cli/behavior/behavior.dart:162:22)
<asynchronous suspension>
#5      advanceShipBehavior (package:cli/behavior/advance.dart:104:23)
<asynchronous suspension>
#6      advanceShips (package:cli/logic.dart:71:29)
<asynchronous suspension>
#7      logic (package:cli/logic.dart:184:7)
<asynchronous suspension>
#8      cliMain (file:///root/space_traders/packages/cli/bin/cli.dart:148:3)
<asynchronous suspension>
#9      main.<anonymous closure> (file:///root/space_traders/packages/cli/bin/cli.dart:154:7)
<asynchronous suspension>
#10     main (file:///root/space_traders/packages/cli/bin/cli.dart:152:3)
<asynchronous suspension>

### Confused hauler transfers

[WARN] 🛸#D  scheduled for 2023-12-04 00:22:33.750 but it is 2s late
🛸#D  Still have 2 cargo, waiting for hauler to arrive.
🛸#D  No haulers at JX78-XF5X, unknown next arrival time for ESEIDEL-7, ESEIDEL-9, checking in 1 minute.
🛸#D  Hauler ESEIDEL-7 is IN_ORBIT to JX78-XF5X arrival -17m, with 0 space available.
🛸#D  Hauler ESEIDEL-9 is IN_ORBIT to JX78-XF5X arrival -7m, with 75 space available.


🛸#11 Still have 4 cargo, waiting for hauler to arrive.
🛸#11 No haulers at JX78-XF5X, unknown next arrival time for ESEIDEL-7, ESEIDEL-9, checking in 1 minute.
🛸#11 Hauler ESEIDEL-7 is IN_ORBIT to JX78-XF5X arrival -7m, with 80 space available.
🛸#11 Hauler ESEIDEL-9 is IN_ORBIT to JX78-XF5X arrival -18m, with 0 space available.

11 is in orbit at X1-JX78-XF5X.  7 is in orbit at X1-JX78-XF5X.

I think this is due to miner haulers not running often? And thus not updating
their transit status?

### Construction doesn't seem to avoid over-buying.

If you disable the "avoid from same source" construction will buy multiple
times of the same final set of units for a contract.  e.g. if only 40 more
are needed, you'll still end up with two 40-sized trades going.

### Teach satellites to ignore exchange-only markets?

### Reduce manual construction of CostedDeal in tests.

### Miner Haulers still confused:

⏱️  2s until 2023-12-10 16:18:27.064
🛸#F  Still have 5 cargo, waiting for hauler to arrive.
🛸#F  No haulers at JX78-B37, unknown next arrival time for ESEIDEL-8, ESEIDEL-15, checking in 1 minute.
🛸#F  Hauler ESEIDEL-8 is IN_ORBIT to JX78-B37 arrival -15m, with 0 space available.
🛸#F  Hauler ESEIDEL-15 is IN_ORBIT to JX78-B37 arrival -3m, with 73 space available.
⏱️  3s until 2023-12-10 16:18:31.255

🛸#A  Still have 3 cargo, waiting for hauler to arrive.
🛸#A  No haulers at JX78-B37, unknown next arrival time for ESEIDEL-8, ESEIDEL-15, checking in 1 minute.
🛸#A  Hauler ESEIDEL-8 is IN_ORBIT to JX78-B37 arrival -13m, with 0 space available.
🛸#A  Hauler ESEIDEL-15 is IN_ORBIT to JX78-B37 arrival -5m, with 77 space available.

### Chart jump gates right after arriving via jump

Right now we don't AFAICT, which means we'll only chart them when we come back
to them.

### Add a deal cache.

Found 0 deals for ESEIDEL-25 from SA91-F21B
[WARN] 🛸#25 No profitable deals near X1-SA91-F21B.
Found 0 deals for ESEIDEL-25 from SA91-F21B
Found 0 deals for ESEIDEL-25 from CM2-FE8A
Found 0 deals for ESEIDEL-25 from VX52-C19B
Found 0 deals for ESEIDEL-25 from KN11-CD8C
Found 0 deals for ESEIDEL-25 from PR56-E21B
Found 0 deals for ESEIDEL-25 from VJ34-D25C
Found 0 deals for ESEIDEL-25 from SS12-E23C
Found 0 deals for ESEIDEL-25 from XK65-Z22D
Found 0 deals for ESEIDEL-25 from XG74-D28D
Found 1 deals for ESEIDEL-25 from UG86-XF4D
Found 0 deals for ESEIDEL-25 from UV60-X25E
Found 1 deals for ESEIDEL-25 from UG2-BZ7A
Found 2 deals for ESEIDEL-25 from ZA48-ZE9C
Found 0 deals for ESEIDEL-25 from MR97-BD5B
Found 0 deals for ESEIDEL-25 from MR11-EF9A
Found 0 deals for ESEIDEL-25 from DU30-E23D
Found 0 deals for ESEIDEL-25 from JR48-ZZ6B
Found 0 deals for ESEIDEL-25 from CH36-CE9E
Found 0 deals for ESEIDEL-25 from RQ80-Z10C
Found 0 deals for ESEIDEL-25 from RJ35-CF7C
Found 0 deals for ESEIDEL-25 from XY32-E22X
Found 0 deals for ESEIDEL-25 from SA11-X20A
Found 0 deals for ESEIDEL-25 from NB49-ZX9F
Found 0 deals for ESEIDEL-25 from FQ47-XX8B
Found 0 deals for ESEIDEL-25 from K12-AX8E
Found 0 deals for ESEIDEL-25 from PZ26-B10B
Found 0 deals for ESEIDEL-25 from ZV29-CD9B
Found 0 deals for ESEIDEL-25 from UN50-E31F
Found 0 deals for ESEIDEL-25 from FC60-A21Z
Found 0 deals for ESEIDEL-25 from MJ51-CD5A
Found 0 deals for ESEIDEL-25 from JC61-E11F
Found 0 deals for ESEIDEL-25 from UY94-F10C
Found 5 deals for ESEIDEL-25 from RN21-X11Z
Found 0 deals for ESEIDEL-25 from YK67-DX5B
Found 2 deals for ESEIDEL-25 from ZU42-BB8C
Found 0 deals for ESEIDEL-25 from DR61-F21C
Found 0 deals for ESEIDEL-25 from GF21-B23F
Found 0 deals for ESEIDEL-25 from KB84-EA5B
Found 0 deals for ESEIDEL-25 from HT92-FF8E
Found 0 deals for ESEIDEL-25 from JD23-B22B
Found 0 deals for ESEIDEL-25 from BZ48-DB9E
Found 0 deals for ESEIDEL-25 from YG19-X24E
Found 0 deals for ESEIDEL-25 from GS85-X12C
Found 0 deals for ESEIDEL-25 from NN43-X25X
Found 0 deals for ESEIDEL-25 from PG23-D25Z
Found 0 deals for ESEIDEL-25 from JC44-A28B
Found 0 deals for ESEIDEL-25 from DK25-E20C
Found 0 deals for ESEIDEL-25 from YA53-FA8E
Found 0 deals for ESEIDEL-25 from RC89-F22B
Found 0 deals for ESEIDEL-25 from SV64-C24Z
Found 0 deals for ESEIDEL-25 from MR51-X18D
Found 0 deals for ESEIDEL-25 from GV91-Z20Z
Found 0 deals for ESEIDEL-25 from KS8-BF9C
Found 0 deals for ESEIDEL-25 from KV83-A23E
Found 0 deals for ESEIDEL-25 from MR47-ZB7E
Found 3 deals for ESEIDEL-25 from SB18-CC5B
Found 0 deals for ESEIDEL-25 from AP97-ZA9Z
Found 0 deals for ESEIDEL-25 from ZZ78-CD5C
Found 2 deals for ESEIDEL-25 from UB21-CE7C
Found 0 deals for ESEIDEL-25 from ZK58-ZD5A
Found 0 deals for ESEIDEL-25 from PM62-CB5Z
Found 0 deals for ESEIDEL-25 from GT14-XZ8B
Found 0 deals for ESEIDEL-25 from DQ95-A27B
Found 0 deals for ESEIDEL-25 from AN36-F20X
Found 0 deals for ESEIDEL-25 from KX96-AD6E
Found 0 deals for ESEIDEL-25 from B40-BF7E
Found 0 deals for ESEIDEL-25 from UX31-AD6E
No nearby markets for ESEIDEL-25
[WARN] 🛸#25 Failed to find better location for trader. Disabling Behavior.trader for ESEIDEL-25 for 10m.
[WARN] 🛸#25 took 17s (0 requests) expected 0.0s

### Double check reachability calculations.

I'm not confident that we're correctly computing reachability.  I think
uncharted jumpgates might be ignored?

### Scan the initial system before starting the rest of the client?

### Command ship no longer knows how to mine (no mine job)

### Failing to find market when no prices?

findBestMarketToSell relies on prices, it probably doesn't need to.

[WARN] 🛸#1  No market for HYDROCARBON. Disabling Behavior.siphoner for ESEIDEL-1 for 10m.
Found 14 deals for ESEIDEL-1 from AC35-C43
🛸#1  Found deal: EQUIPMENT                  AC35-K90      2,191c -> AC35-A1       3,135c  +37,472c (43%) 5m 127c/s  87,928c
🛸#1  Cargo hold not empty, finding market to sell HYDROCARBON.
🛸#1  No nearby market to sell HYDROCARBON, jetisoning cargo!
[WARN] 🛸#1  Jettisoning 40 HYDROCARBON
🛸#1  Beginning route to AC35-K90 (3m)
🛸#1  No market at AC35-C43, cannot refuel, need to replan.
🛸#1  Setting flightMode to DRIFT
🛸#1  Insufficient fuel, drifting to AC35-K90
[WARN] 🛸#1  Fuel low: 126 / 400


### Include cooldowns in route planning.

e.g.

] showRoute X1-GN97-A1 X1-JX78-A1 RDDEV-1
 hops:11 eta:42m46s cost:-45,975 debug:32ms/1,457
  eta  fuelCost  fuelB  lvFuel  act       mode    from          to              arCd  arFuel
--------------------------------------------------------------------------------------------
  37s         0      0     222  nav       BURN    X1-GN97-A1    X1-GN97-E54      0ms     116
1m30s      -225      3     400  nav       BURN    X1-GN97-E54   X1-GN97-I63      0ms      42
3m18s      -225      3     342  nav       CRUISE  X1-GN97-I63   X1-GN97-I62      0ms     123
  0ms   -15,000      0     123  jump      CRUISE  X1-GN97-I62   X1-Z62-X19E      16m     123
  16m         0      0     123  cooldown  CRUISE  X1-Z62-X19E   X1-Z62-X19E      0ms     123
  0ms   -15,000      0     123  jump      CRUISE  X1-Z62-X19E   X1-MR11-EF9A     16m     123
  16m         0      0     123  cooldown  CRUISE  X1-MR11-EF9A  X1-MR11-EF9A     0ms     123
  0ms   -15,000      0     123  jump      CRUISE  X1-MR11-EF9A  X1-JX78-I60      16m     123
3m18s      -150      2     323  nav       CRUISE  X1-JX78-I60   X1-JX78-I61   12m42s     104
 1m9s      -150      2     304  nav       BURN    X1-JX78-I61   X1-JX78-K91   11m33s      46
  54s      -225      3     346  nav       BURN    X1-JX78-K91   X1-JX78-A1    10m39s     158

### Teach extract_scores to consider jettisoning.

Try planning out various simulations for each mine and judge based on expected
total c/s? (or maybe c/r?) rather than median prices at the markets.

### Add a script to examine extract/market scores of a single market:

So I can better understand why we don't chose specific mining locations, e.g.
for a supply chain.

% dart run bin/exports_supply_chain.dart 
Sourcing FAB_MATS for AC35-I59
Shuttle FAB_MATS from AC35-F51 (SCARCE, RESTRICTED) to AC35-I59 (no market) distance = 449
 Manufacture FAB_MATS at AC35-F51 (SCARCE, RESTRICTED)
  Shuttle IRON from AC35-H55 (SCARCE, RESTRICTED) to AC35-F51 (LIMITED, GROWING) distance = 90
   Manufacture IRON at AC35-H55 (SCARCE, RESTRICTED)
    Extract IRON_ORE from AC35-C43, deliver to AC35-H55 (SCARCE, GROWING) distance = 158
  Extract QUARTZ_SAND from AC35-C43, deliver to AC35-F51 (SCARCE, WEAK) distance = 229

This might be fixed by considering jettisoning goods.

### Support jumping when the other side of the gate is uncharted.

The client doesn't seem to do this right now.  But did do so once I ran the
jumpgates.dart script.

### Waypoint cache is not using maxAge.

We should be scanning a system before we travel to it.  But right now we
don't respect the maxAge so we'll think it's always uncharted.

### Slow server can break client.

Timed out (1s) waiting for response?
Timed out (2s) waiting for response?
Timed out (1s) waiting for response?
Timed out (1s) waiting for response?
Timed out (2s) waiting for response?
Timed out (1s) waiting for response?
Unhandled exception:
TimeoutException after 0:00:30.000000: Future not completed

### Why is this probe stuck?

Charted all known systems, starting asteroid charting.
[WARN] 🛸#28 (charter) took 3s (0 requests) expected 0.0s
🛸#28 JY88-C20A (ASTEROID) is missing chart, routing.
🛸#28 Beginning route to JY88-C20A (6m)
🛸#28 🛫 to JY88-C20A ASTEROID (6m)

### Check if we artificially devalue fuel trades

We include fuel price at destination when evaluating trades.  But if we're
trading fuel we don't want to do that. We could refuel from cargo and the price
is also going to change as part of our delivery.

### Write a script to profile deal finding across multiple systems.

### Do I consider cost when moving to another system for trading?

### Contract crash??

[WARN] 🛸#F  Expected 258,752c profit (9c/s), got 1,720c (0c/s) in 12:36:02, expected 07:17:49
Unhandled exception:
ApiException 400: {"error":{"message":"Agent ESEIDEL already has an active contract.","code":4511,"data":{"agentSymbol":"ESEIDEL","contractId":"clqa10azr2q0es60cv0d1t4q1"}}}
#0      FleetApi.negotiateContract (package:openapi/api/fleet_api.dart:1335:7)
<asynchronous suspension>
#1      negotiateContractAndLog (package:cli/net/actions.dart:543:20)
<asynchronous suspension>
#2      acceptContractsIfNeeded (package:cli/behavior/trader.dart:545:9)
<asynchronous suspension>
#3      _initDeal (package:cli/behavior/trader.dart:855:5)
<asynchronous suspension>
#4      MultiJob.run (package:cli/behavior/behavior.dart:154:22)
<asynchronous suspension>
#5      advanceShipBehavior (package:cli/behavior/advance.dart:107:23)
<asynchronous suspension>
#6      advanceShips.<anonymous closure> (package:cli/logic.dart:101:21)
<asynchronous suspension>
#7      captureTimeAndRequests (package:cli/net/counts.dart:66:18)
<asynchronous suspension>
#8      advanceShips (package:cli/logic.dart:99:29)
<asynchronous suspension>
#9      logic (package:cli/logic.dart:211:7)
<asynchronous suspension>
#10     cliMain (file:///root/space_traders/packages/cli/bin/cli.dart:148:3)
<asynchronous suspension>
#11     main.<anonymous closure> (file:///root/space_traders/packages/cli/bin/cli.dart:154:7)
<asynchronous suspension>
#12     main (file:///root/space_traders/packages/cli/bin/cli.dart:152:3)
<asynchronous suspension>

about 2pm on Sunday 12/24.

```json
 {
  "id": "clqa10azr2q0es60cv0d1t4q1",
  "factionSymbol": "ASTRO",
  "type": "PROCUREMENT",
  "terms": {
   "deadline": "2023-12-24T21:55:42.369Z",
   "payment": {
    "onAccepted": 1950,
    "onFulfilled": 6915
   },
   "deliver": [
    {
     "tradeSymbol": "PLATINUM_ORE",
     "destinationSymbol": "X1-AC35-B7",
     "unitsRequired": 45,
     "unitsFulfilled": 0
    }
   ]
  },
  "accepted": true,
  "fulfilled": false,
  "expiration": "2023-12-18T21:55:42.369Z",
  "deadlineToAccept": "2023-12-18T21:55:42.369Z"
 }
 ```

### Add limit for how long low-value deals can go.

e.g. 7hr for 1c/s isn't worth it.  But 30m for 1c/s might be.
7hr for 7c/s is fine.

### Make the idle queue resume where it left off.

Right now it takes a long time to get back to the end of the queue.

### Charters are too slow.

🛸#36 Charted reachable systems within 5 jumps, charting asteroids in X1-TM24.
[WARN] 🛸#36 (charter) took 2s (0 requests) expected 0.0s
🛸#36 TM24-Z65F (ASTEROID) is missing chart, routing.
[WARN] 🛸#36 Beginning route to TM24-Z65F (10m)
🛸#36 🛫 to TM24-Z65F ASTEROID (10m)
🛸#3C 🗺️  X1-YG47-A53F - ASTEROID - Common Metal Deposits, Deep Craters, Shallow Craters
🛸#3C Charted reachable systems within 5 jumps, charting asteroids in X1-YG47.
[WARN] 🛸#3C (charter) took 3s (0 requests) expected 0.0s
🛸#3C YG47-C56C (ASTEROID) is missing chart, routing.
[WARN] 🛸#3C Beginning route to YG47-C56C (42m)
🛸#3C 🛫 to YG47-C56C ASTEROID (42m)
🛸#39 🗺️  X1-FN61-X16B - ASTEROID - Common Metal Deposits
🛸#39 Charted reachable systems within 5 jumps, charting asteroids in X1-FN61.
[WARN] 🛸#39 (charter) took 3s (0 requests) expected 0.0s

### Traders too slow.

🛸#F  🛫 to PK16-J63 FUEL_STATION (5m) spent 122 fuel
[WARN] 🛸#F  (trader) took 4s (2 requests) expected 0.8s

### canJump should always use a cached version?

### Make it possible for ships other than command to buy ships.

Command ship can get stuck on many hour trades and then not be able to buy
new ships even after they're queued.

### Prefer shorter trades over longer at the same c/s?

Would only need to apply to trades at low c/s.

### Bring back phases.

- Some sort of initial phase (plan trades based on import/export?)
- Ramping up to a certain number of traders.
- Focusing on construction
  (Need to fix supply chain logic to handle entire chains.)
- Ramping up probes + exploring
  (Don't buy probes before opening the jump gate, or they'll start
  system watching instead of charting.)
- Turning off mining and replacing with heavy freighters.

### Assign miner haulers only when a miner is active at the assigned waypoint.

### Write logic to predict how long until current behavior is resolved.

### Logic to find the closest ship to a waypoint (for task start).

### Write a script to predict cash flow.
* Can us the "when done" logic to predict when we sell inventory.
* Can use the historical data for miners.

### Add a system for managing cash-flow to avoid missing trades from low cash.

### Mining Haulers still confused:

🛸#E  Still have 12 cargo, waiting for hauler to arrive.
🛸#E  No haulers at TV94-B44, unknown next arrival time for ESEIDEL-6, checking in 1 minute.
🛸#E  Hauler ESEIDEL-6 is IN_ORBIT to TV94-B44 arrival -30m, with 0 space available.

### Make sure that hauler routes are cruise-able with the given hauler.

### Script for tracking construction.

Lists current status of the construction.
Lists any in-progress construction deals.
Lists status of construction supply chain?

### Teach ships how to refuel from cargo.

That way miner haulers can bring fuel with them when heading to a mine and then
refuel there, so they have enough to get back to the market.

### Gate probe buying off of # of uncharted systems?

e.g. when we know of 10 uncharted systems by 1 probe? up to a limit?
Could do similar with trades? Buy N haulers when we have N available trades?
And maybe mining?  When we have N available mines with score above x?

### Should disable jumping (for charters at least?) when low on cash?

### Making trades w/o prices would help early game (and for new systems).

### Regenerate connectivity every time we chart a jumpgate.

Presumably just a bool on centralCommand that the outer loop can check/clear.

Need two things:
1. A way to know that we should re-gen.
2. A list of jumpgates to add?  (Or do we just re-start the scan?)
  If we add a single jump gate we'd want to know it's distance?
  Or do we just not care and call it 0 each time?

### Set up a siphoner on each gas giant?  Maybe an ORE_HOUND + Siphoner?

Turns out we need squads too since the closest hydrocarbon market is an exchange
rather than an import.

### Use systems.json to find all the systems with lots of markets.

I suspect that "home systems" look different only by types / number of waypoints.

### Planning fail.

🛸#1  ✈️  to AQ24-D43, -7s left
🛸#1  ✍️  market data @ AQ24-D43
🛸#1  ⛽   2 FUEL                           ⚖️    2 x     73c =   -146c -> 🏦 668,584c
🛸#1  💸  35 ADVANCED_CIRCUITRY  -46% -6,291c per  35 x  7,257c = -253,995c -> 🏦 414,589c
🛸#1  Purchased 35 of ADVANCED_CIRCUITRY, still have 5 units we would like to buy, looping.
🛸#1  ✍️  market data @ AQ24-D43
🛸#1  💸   5 ADVANCED_CIRCUITRY  -40% -5,365c per   5 x  8,183c = -40,915c -> 🏦 373,674c
🛸#1  Purchased 5 ADVANCED_CIRCUITRY @ 8183 (expected 9,134c) = -40,915c
🛸#1  Starting: AQ24-D43 to AQ24-I53 speed: 30 max-fuel: 400
navCruise       AQ24-D43  AQ24-E45 2m 131 fuel
refuel          AQ24-E45  AQ24-E45 0ms 0 fuel
navCruise       AQ24-E45  AQ24-I53 6m 398 fuel
in 8m uses 529 fuel

[WARN] 🛸#1  Beginning route to AQ24-I53 (8m)
🛸#1  🛫 to AQ24-E45 MOON (2m) spent 131 fuel

[WARN] 🛸#1  late 3s
🛸#1  ⛽   2 FUEL                 +1%  +1c per   2 x     74c =   -148c -> 🏦 385,560c
🛸#1  Beginning route to AQ24-I53 (6m)
🛸#1  Setting flightMode to DRIFT
🛸#1  Insufficient fuel, drifting to AQ24-I53
🛸#1  🛫 to AQ24-I53 JUMP_GATE (55m) spent 1 fuel

### Show trade volumes in deals_nearby.

### Account for incoming purchases when planning trades sourcing from the same spot?

### Planned a trade, then tried to jump and failed, cleared state

🛸#29 Found deal: ANTIMATTER                 AQ24-I53     12,161c -> GC80-I53     13,859c   +2,284c  (1%) 0ms 2,284c/s 247,178c
🛸#29 Beginning route to AQ24-I53 (0ms)
🛸#29 🥶 for 2h

This might be correct to clear the trade if we have to wait?  But I'm also
not confident that won't end up resetting trades between jumps during client
restarts?

dart run bin/behavior.dart 29
[
 {
  "behavior": "trader",
  "shipSymbol": "ESEIDEL-29",
  "deal": null,
  "routePlan": null,
  "buyJob": null,
  "deliverJob": null,
  "shipBuyJob": null,
  "mountJob": null,
  "pickupJob": null,
  "extractionJob": null,
  "systemWatcherJob": null,
  "jobIndex": 0
 }
]

"cooldown": {
  "shipSymbol": "ESEIDEL-29",
  "totalSeconds": 6944,
  "remainingSeconds": 6943,
  "expiration": "2024-03-01T18:17:10.909Z"
},

### Move logs into db.

### Add explorer/warp logic.

- Generate a list of places to warp to.
- Model how long warping takes:
https://github.com/SpaceTradersAPI/api-docs/wiki/Travel-Fuel-and-Time
- Plan a route to the warp point (which may include jump gates)?

### SystemWatcher should clear after every visit, even if it's already charted.

### Figure out how to trace execution of the client (and show in systrace).

### Build a profit/loss statement.

### Build a cash flow statement.

### This seems wrong?  Is it considering jumping?

Found 3 deals for ESEIDEL-49 from AQ24-I53
🛸#49 Found deal: LIQUID_HYDROGEN            AQ24-C40          3c -> AQ24-G48         32c   +3,648c (414%) 9m   6c/s     882c
🛸#49 ⛽   4 FUEL                 +3%  +2c per   4 x     74c =   -296c -> 🏦 1,667c
🛸#49 Market at AQ24-I53 doesn't buy FABRICS
🛸#49 Cargo hold not empty, finding market to sell FABRICS.
🛸#49 Selecting AQ24-K85 earns 28,650c extra (including 14,147c for fuel) over 6s (4775.0/s)
🛸#49 Beginning route to AQ24-K85 (5m)
🛸#49 🛫 to AQ24-K85 PLANET (5m) spent 366 fuel

### Replace findBetterTradeLocation with something cheaper.

Probably have some logic which computes the number of trades available
per-system, and then reassigns ships to the closest system with available trades?

Maybe more generally we should be computing how many traders a given system
can handle and re-balancing our traders accordingly?  Similar to what we do
with system-watchers?

### Siphoners don't seem to respond to disabling mining?

🛸#12 ✈️  to AQ24-C39, -3ms left
🛸#11 ✈️  to AQ24-C40, -6ms left
🛸#11 ⛽   1 FUEL               +400% +288c per   1 x    360c =   -360c -> 🏦 927,035c
🛸#11 🤝   4 HYDROCARBON         -96% -50c per   4 x      2c =     +8c -> 🏦 927,043c

And the fuel costs are quite high.

### Predict prices before purchase and log when they differ?

### Profile and improve speed of idle_queue.dart

### Write a script to distribute traders.

### Write logic to pick a place to buy a ship and then the closest/fastest ship to buy there.

### Remove MarketPrices from cache (significant load time).

### Add warp time/fuel prediction.

Looks correct:
warpCruise      KH4-C10C  JV44-A1 18m 632 fuel
actual:
🛸#64 🛫 to JV44-A1 PLANET (18m) spent 632 fuel

### Buying doubles?

🛸#64 ✈️  to JV44-C42, -14ms left
🛸#64 ✍️  shipyard data @ X1-JV44-C42
🛸#64 Purchased SHIP_PROBE for 21,013c -> 🏦 47,009,953c
🛸#64 Bought ship: ESEIDEL-98
[WARN] 🛸#64 Purchased ESEIDEL-98 (SHIP_PROBE)!
[WARN] Adding missing ship ESEIDEL-98
🛸#98 ✍️  shipyard data @ X1-JV44-C42
🛸#98 Purchased SHIP_PROBE for 21,484c -> 🏦 46,988,469c
🛸#98 Bought ship: ESEIDEL-99
[WARN] 🛸#98 Purchased ESEIDEL-99 (SHIP_PROBE)!
[WARN] Adding missing ship ESEIDEL-99
🛸#99 ✍️  market data @ JV44-C42
🛸#99 Charted reachable systems within 5 jumps, charting asteroids in X1-JV44.
[WARN] 🛸#99 Charted all known systems Disabling Behavior.charter for ESEIDEL-99 for 1h.
🛸#99 JV44-C43 is missing recent (3d) market data, routing.
[WARN] 🛸#99 Beginning route to JV44-C43 (6m)
🛸#99 🛫 to JV44-C43 FUEL_STATION (6m)
[WARN] 🛸#98 Charted all known systems Disabling Behavior.charter for ESEIDEL-98 for 1h.
🛸#98 JV44-G52 is missing recent (3d) market data, routing.
[WARN] 🛸#98 Beginning route to JV44-G52 (14m)
🛸#98 🛫 to JV44-G52 PLANET (14m)

How did 98 get a buy job!?


🛸#7  surveyor  ✈️  to TA36-C37, -10ms left
🛸#7  surveyor  ✍️  shipyard data @ X1-TA36-C37
🛸#7  surveyor  Purchased SHIP_SIPHON_DRONE for 46,052c -> 🏦 666,538c
🛸#7  surveyor  Bought ship: ESEIDEL2-8
[WARN] 🛸#7  surveyor  Purchased ESEIDEL2-8 (SHIP_SIPHON_DRONE)!
[WARN] Adding missing ship ESEIDEL2-8
🛸#8  siphoner  ✍️  shipyard data @ X1-TA36-C37
🛸#8  siphoner  Purchased SHIP_SIPHON_DRONE for 47,203c -> 🏦 619,335c
🛸#8  siphoner  Bought ship: ESEIDEL2-9
[WARN] 🛸#8  siphoner  Purchased ESEIDEL2-9 (SHIP_SIPHON_DRONE)!
[WARN] Adding missing ship ESEIDEL2-9
🛸#9  siphoner  Beginning route to TA36-C36 (23s)
🛸#9  siphoner  🛫 to TA36-C36 GAS_GIANT (23s) spent 1 fuel
🛸#8  siphoner  Beginning route to TA36-C36 (23s)
🛸#8  siphoner  🛫 to TA36-C36 GAS_GIANT (23s) spent 1 fuel

I think it happens due to ships not being added immediately after purchase?

🛸#8  siphoner  ✈️  to TA36-H51, -6ms left
🛸#8  siphoner  ✍️  shipyard data @ X1-TA36-H51
🛸#8  siphoner  Purchased SHIP_MINING_DRONE for 39,274c -> 🏦 653,810c
🛸#8  siphoner  Bought ship: ESEIDEL2-A
[WARN] 🛸#8  siphoner  Purchased ESEIDEL2-A (SHIP_MINING_DRONE)!
[WARN] Adding missing ship ESEIDEL2-A
🛸#A  miner     ✍️  shipyard data @ X1-TA36-H51
🛸#A  miner     Purchased SHIP_MINING_DRONE for 41,176c -> 🏦 612,634c
🛸#A  miner     Bought ship: ESEIDEL2-B
[WARN] 🛸#A  miner     Purchased ESEIDEL2-B (SHIP_MINING_DRONE)!
[WARN] Adding missing ship ESEIDEL2-B
[WARN] 🛸#B  miner     No mine job. Disabling Behavior.miner for ESEIDEL2-B for 10m.
[WARN] 🛸#A  miner     No mine job. Disabling Behavior.miner for ESEIDEL2-A for 10m.

My theory is this happens when we do top of loop in between when the ship was
purchased and when the new ship is scheduled?

How does it end up with a second buy job?

### Routing trouble in trade planning?

🛸#1  ✈️  to AQ24-C39, -5ms left
[WARN] No route from AQ24-C39 to BT63-C39
[WARN] No route from AQ24-C39 to JV44-C42
[WARN] No route from AQ24-C39 to JV44-G52
[WARN] No route from AQ24-C39 to BT63-G47
[WARN] No route from AQ24-C39 to JV44-E49
[WARN] No route from AQ24-C39 to BT63-F45
[WARN] No route from AQ24-C39 to UT62-G50
[WARN] No route from AQ24-C39 to UT62-C39
[WARN] No route from AQ24-C39 to BT63-E44
🛸#1  Selecting AQ24-G48 earns 192c extra (including -72c for fuel) over 13s (7.4/s)
🛸#1  Traveling to AQ24-G48 to sell.
🛸#1  Beginning route to AQ24-G48 (2m)
🛸#1  🛫 to AQ24-G48 PLANET (2m) spent 94 fuel

### Assign unsused probes.

Each system can have "slots" based on the number of connected systems without charts.
Assign up to half the slots?
Do some sort of proximity based matching?

Currently probes (and traders) do self-assign which can cause probes to "grab"
far-away systems, even though a closer probe would have done better.

Same thing could work for traders.  Compute the number of deals above a
certain c/s, starting from that system and assign up to a certain capacity
level with a similar matching algorithm?

### finish warp pathing.

Pre-compute the path to jumpgate and path from jumpgate.
And add those costs as costs to beginning or ending with a jump.
If those costs are passed into the warp planner the planner will then correctly
choose to warp small distances to adjacent systems to cross large distances
within a system.  It also simplifies the inter-system planning since
we don't have to modify actions after the fact, we just pass in costs to
the planner?

### Unify warp planner into waypoint planner?

- Add warp planner.
- Add logic for explorers to go to more systems (via warp).

### Move constructionSellOpps, etc. onto a ConstructionState object?

### Fix Refuel navigation to actually work (see TODO in navigation.dart)

### Move constructionSellOpps, etc. onto a ConstructionState object?

### Squads.dart not listing haulers?

It (and all other scripts) aren't setting up the Config phase correctly.
Should make config a getter, and have it log if the phase isn't set.

root@ubuntu-s-2vcpu-4gb-sfo3-01:~/space_traders/packages/cli# dart run bin/squads.dart 
2 squads
Squad 0: mine @ TA36-XE5F
   6 MINING_DRONE TA36-XE5F 4/15
   7 SURVEYOR TA36-XE5F 
   B MINING_DRONE TA36-XE5F 0/15
   D SURVEYOR TA36-XE5F 
   F MINING_DRONE TA36-XE5F 6/15
  11 MINING_DRONE TA36-XE5F 9/15
Squad 1: mine @ TA36-B9
   A MINING_DRONE TA36-B9 7/15
   C SURVEYOR TA36-B9 
   E MINING_DRONE TA36-B9 10/15
  10 MINING_DRONE TA36-B9 0/15
root@ubuntu-s-2vcpu-4gb-sfo3-01:~/space_traders/packages/cli# dart run bin/fleet.dart
Fleet: 1 Frigate, 1 Probe, 11 Light Freighter, 12 Drone
1 command (trader) 40/40
   FERTILIZERS              40 x 212c     = 8,480c
   enroute to TA36-E44 MOON in 31s
   FERTILIZERS                TA36-G48        178c -> TA36-E44        212c   +1,216c (17%) 2m  10c/s   7,264c
   duration: 2m
2 probe (systemWatcher) SATELLITE 
   enroute to TA36-H52 MOON in 57s
3 trader (minerHauler) 47/80
   ALUMINUM_ORE             47 x 20c      = 940c
   Orbiting TA36-XE5F ENGINEERED_ASTEROID
4 trader (minerHauler) 80/80
   FUEL                      5 x 68c      = 340c
   SILICON_CRYSTALS         34 x 47c      = 1,598c
   COPPER_ORE                2 x 22c      = 44c
   IRON_ORE                 27 x 23c      = 621c
   QUARTZ_SAND              12 x 19c      = 228c
   enroute to TA36-B7 ASTEROID_BASE in 1m
5 trader (minerHauler) 0/80
   Orbiting TA36-XE5F ENGINEERED_ASTEROID
