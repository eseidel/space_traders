Client that talks `protocol` to `server`, shared by `cli` and `web`.

Allows me to slowly move logic out of `cli` and into `server`.

Separate from `protocol` since `server` does not include `client`.