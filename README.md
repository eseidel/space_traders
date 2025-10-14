[![codecov](https://codecov.io/gh/eseidel/space_traders/branch/main/graph/badge.svg?token=YU4WO0ULKW)](https://codecov.io/gh/eseidel/space_traders)

# Space Traders in Dart

A Dart client for spacetraders.io.

## Packages
* [cli](packages/cli) - The main CLI for "playing" the game.
* [db](packages/db) - Postgres bindings for storing client state.
* [openapi](packages/openapi) - A generated Dart client for the Space Traders API.
* [server](packages/server) - A very basic server for supporting the UI.
* [types](packages/types) - Shared types between the packages.
* [ui](packages/ui) - A Flutter UI for the Space Traders API.

`cli`, `db` and `types` are the most complete and useful packages.
`openapi` is generated (and pretty terrible code).
`server` and `ui` are mostly stubs.

## Setup

This should work on any platform, but probably runs best on Linux.

I use a slice on DigitalOcean (any provider would do).  You'll want at least
2GB to run alone (dart + postgres), 4GB or more if you plan to use Visual Studio over
SSH (the Dart Analyzer is very memory intensive).

The code assumes you're using the latest stable Dart.

### Installing Flutter & Dart
The easiest way to get Dart is typically via Flutter.  See
https://flutter.dev/docs/get-started/install for instructions.

On ubuntu:
```
sudo snap install flutter --classic
flutter
```

### Running as `root`

If you're running as root, you'll also want to disable `flutter`'s warning
messages about running as root (which also show up when running `dart` if
installed via `flutter`).

```
echo "export BOT=true" >> $HOME/.bashrc
source $HOME/.bashrc
```

## Database Setup

Follow the instructions in packages/db/README.md before continuing.

## Running

Set `ST_AGENT` to your desired agent name.

You can reserve your name by donating to spacetraders.

```
export ST_AGENT=your_name
```

And then otherwise just run:
```
snap install docker
docker compose up --build
```

You only need to set `ST_AGENT` for runs when expecting to need to register
a new agent (otherwise its saved in the db along with the agent token).

## Extra setup for Development

I'd recommend adding `very_good` for ease of getting all the packages.
```
dart pub global activate very_good_cli
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> $HOME/.bashrc
source $HOME/.bashrc
```

Checkout and run `dart test` to make sure everything is working:
```
git clone https://github.com/eseidel/space_traders.git
cd space_traders
very_good packages get -r
cd packages/cli
dart test
```

You may also want to set up git if you haven't
```
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

## Pieces

### Database

See instructions in packages/db/README.md.

Note: currently our notify/listen code seems to cause a leak on the server
side of the connection.  Thus you may need to restart both the cli and
network executor every 12 hours or so, depending on how much RAM you have.

I run the cli, db and network executor all in the same instance which has
4GB of RAM.  I typically restart the cli and network executor every 12 hours.

### Network Executor

The network executor is the rate limited client for the Space Traders API.
It's a separate process to allow us to eventually have multiple clients
running at once.

The CLI does not *require* the network executor (it knows how to do)
in process rate limiting, but it's recommended if you plan to be running
things for long periods of time.

I typically run the network executor in a separate terminal window or tmux
or screen session.  e.g.

```
screen -S net
cd packages/cli
dart run bin/network_executor.dart
```

### CLI

The CLI is the main way to play the game.  It's a single process that
handles all the game logic and logging.  It does require user input
to register, but after that it can run unattended.

Similar to the network executor, I typically run the CLI in a separate
terminal window or tmux or screen session.  e.g.

```
screen -S cli
cd packages/cli
dart run
```

#### Example CLI output

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

### cli bin/ directory

There are a variety of scripts I've written in packages/cli/bin which can be
used to query the database, or do other things.  They're not documented
yet, but you can see what they do by reading the source.  I've tried to
sort them by area of interest.

Most scripts run completely on cached data, but the ones which do talk to
the API are smart enough to use the db and network executor if available
otherwise they will use the API directly via an in-process rate limiter.

## Development

### Testing

You can run individual packages tests locally by cd'ing into the package
directory and running `dart test`.

There are also tools like `very_good` which can run tests across multiple
packages, e.g. `dart pub global activate very_good_cli`
then `very_good test -r`.

### Coverage

I've slowly been adding tests and increasing coverage.  See
[codecov](https://codecov.io/gh/eseidel/space_traders) for the current
coverage.

You can run all the tests locally and collect coverage by running
`./coverage.sh`.  This will run all the tests and generate a coverage
report in `coverage/lcov.info`.  You can then view the coverage report
by running `genhtml coverage/lcov.info` (on linux) and opening the
generated `index.html` file in your browser.  There are also a variety
of other tools for viewing lcov.info files, including extensions for
VSCode.  Mostly I just use codecov for viewing coverage.

## Reset day checklist
```
./packages/db/tools/backup.sh # Optionally save the db contents.
docker compose down # Shut down services
sudo rm -rf db_data # Remove existing postgres.
```

* Regenerate `packages/openapi` if needed.
* get a new token from my.spacetraders.io
* import the token via cli/bin/import_token.
* cli will fail until waypoints have been populated by idle.

### Generating `packages/openapi`
```
cd packages/cli
dart run space_gen -i https://api.spacetraders.io/v2/documentation/json -o ../openapi --openapi
```

## TODO

See [TODO.md](TODO.md) for a list of of issues I'm working on.
