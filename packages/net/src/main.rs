use anyhow::Result;
use postgres::{Client, NoTls};

struct Request {
    _id: i32,
    url: String,
    body: String,
}

impl Request {
    fn empty(url: &str) -> Request {
        Request {
            _id: 0,
            url: String::from(url),
            body: String::new(),
        }
    }
}

fn main() -> Result<()> {
    let mut client = Client::connect(
        "postgresql://postgres:password@localhost/spacetraders",
        NoTls,
    )?;

    client.batch_execute(
        "
        CREATE TABLE IF NOT EXISTS request_ (
            id              SERIAL PRIMARY KEY,
            url             VARCHAR NOT NULL,
            body            VARCHAR NOT NULL
            )
    ",
    )?;

    let requests = vec![
        Request::empty("https://api.spacetraders.io/v2/my/agent"),
        Request::empty("https://api.spacetraders.io/v2/my/agent"),
        Request::empty("https://api.spacetraders.io/v2/my/agent"),
    ];

    for request in &requests {
        client.execute(
            "INSERT INTO request_ (url, body) VALUES ($1, $2)",
            &[&request.url, &request.body],
        )?;
    }

    for row in client.query("SELECT id, url, body FROM request_", &[])? {
        let request = Request {
            _id: row.get(0),
            url: row.get(1),
            body: row.get(2),
        };
        println!("{} with {}", request.url, request.body);
    }

    let client = reqwest::blocking::Client::new();
    let res = client
        .get("http://localhost:8000/")
        .body("the exact body that is sent")
        .send()?;
    print!("{}", res.text()?);

    Ok(())
}
