use anyhow::Result;
use postgres::{Client, NoTls};

struct Request {
    _id: i32,
    priority: i32,
    method: String,
    url: String,
    body: String,
}

impl Request {
    fn empty(url: &str, priority: i32) -> Request {
        Request {
            _id: 0,
            priority,
            method: String::from("GET"),
            url: String::from(url),
            body: String::new(),
        }
    }
}

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

    for request in &requests {
        db.execute(
            "INSERT INTO request_ (url, body, priority, method) VALUES ($1, $2, $3, $4)",
            &[
                &request.url,
                &request.body,
                &request.priority,
                &request.method,
            ],
        )?;
    }
    db.batch_execute("NOTIFY request_")?;
    println!("Added {} requests to the database", requests.len());
    Ok(())
}
