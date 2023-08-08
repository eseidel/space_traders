use anyhow::Result;
use postgres::{Client, NoTls};

use net::*;

fn main() -> Result<()> {
    let mut db = Client::connect(
        "postgresql://postgres:password@localhost/spacetraders",
        NoTls,
    )?;

    let requests = vec![
        Request::empty("https://api.spacetraders.io/v2/my/3", 3),
        Request::empty("https://api.spacetraders.io/v2/my/2", 2),
        Request::empty("https://api.spacetraders.io/v2/my/1", 1),
        Request::empty("https://api.spacetraders.io/v2/my/3", 3),
        Request::empty("https://api.spacetraders.io/v2/my/2", 2),
        Request::empty("https://api.spacetraders.io/v2/my/1", 1),
    ];
    let count = requests.len();

    for request in requests.into_iter() {
        queue_request(&mut db, request)?;
    }
    db.batch_execute("NOTIFY request_")?;
    println!("Added {} requests to the database", count);
    Ok(())
}
