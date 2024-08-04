[![codecov](https://codecov.io/gh/eseidel/space_traders/branch/main/graph/badge.svg?token=YU4WO0ULKW)](https://codecov.io/gh/eseidel/space_traders)

# Space Traders CLI

A collection of scripts for playing https://spacetraders.io/ from the command line.

## Usage

These scripts require the db to be set up and running.  See ../db/README.md
for setup of postgres.

Current setup expects 3 terminals:

Running:
1. `dart run bin/network_executor.dart`
2. `dart run bin/cli.dart`
3. `dart run bin/idle_queue.dart`

The network_executor and db must be running before the other scripts will work.

## Screen config

You'll probably want to run the commands within a screen session.

You'll need to configure screen if you want to be able to scroll up with the
scroll wheel.

```
echo "termcapinfo xterm* ti@:te@" >> $HOME/.screenrc
```

## Development

Most of the scripts in `bin/` are about providing analysis from the state
of the game.  `bin/simulate.dart` is one of the various planning scripts
(for exploring what different configurations could do).