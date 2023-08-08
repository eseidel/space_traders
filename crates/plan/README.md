# New CLI

This is a re-write of my Dart cli, except now in Rust on top of a new
multi-process architecture.

Starting with the simplest possible strategy.

* Always runs at full rate limit.
* Fills any empty time with status calls.


Most basic strategy
* Leave probe alone (maybe dock it)?
* Send command ship (and all miners) to mine.
* Buy a new ship when possible (and have requests available)


Mining loop
* Go to mine.
* Undock if needed
* Mine
* Dock if needed
* Sell all goods
* Repeat






Problem we're solving
* Trying to let multiple ships plan in parallel without slowing each other down.
* Could use existing Dart (and just move networking off)?
* How do we reconcile this with central planning?
* What sort of central planning do we need?
* Buy a ship?  Go do a delivery?


Arch
* Central Planner
* Ship Planner
* DB
* Network process

## Central 

## Ship Planner
* Run one per ship
* 