# Space Traders CLI

A collection of scripts for playing https://spacetraders.io/ from the command line.

## Usage

`dart run` will run the main script, which goes in an infinite loop mining.
It will ask you to register if it can't find an auth_token.txt file.

It's smart enough that you can kill it and it will resume where it left off.