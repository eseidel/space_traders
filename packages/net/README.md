# Net

This is an experiment to try moving the spacetraders client towards being
multi-process.

This process would be the one handling the network interactions with the server.
It will read/write from a postgres database which is filled by other processes
with network requests.
It will handle 429 rate limit errors.
