use anyhow::Result;
use postgres::fallible_iterator::FallibleIterator;

struct Request {
    _id: i64,
    priority: i32,
    url: String,
    body: String,
}

// struct Response {
//     _id: i32,
//     url: String,
//     body: String,
// }

fn main() -> Result<()> {
    let mut db = postgres::Client::connect(
        "postgresql://postgres:password@localhost/spacetraders",
        postgres::NoTls,
    )?;

    let requests_per_second = 1;
    let time_between_requests = std::time::Duration::from_millis(1000 / requests_per_second);
    let net = reqwest::blocking::Client::new();
    let mut next_request_time = std::time::Instant::now();

    // Could be any name, just needs to be the same as the NOTIFY.
    db.batch_execute("LISTEN request_")?;

    loop {
        // Wait until the next request time.
        let now = std::time::Instant::now();
        if next_request_time > now {
            std::thread::sleep(next_request_time - now);
        }
        // Every wakeup, get a new request, and make it for the server.
        // Set the next request time.
        next_request_time = std::time::Instant::now() + time_between_requests;

        // Get one request of the highest priority.
        let result = db.query_one(
            "SELECT id, priority, url, body FROM request_ ORDER BY priority DESC LIMIT 1",
            &[],
        );
        if let Ok(row) = result {
            let request = Request {
                _id: row.get(0),
                priority: row.get(1),
                url: row.get(2),
                body: row.get(3),
            };
            println!("{} {} with {}", request.priority, request.url, request.body);
            let res = net
                .get("http://localhost:8000/")
                .body("the exact body that is sent")
                .send()?;
            let text = res.text()?;
            println!("{}", text);
            // post the result.
            db.execute(
                "INSERT INTO response_ (url, body) VALUES ($1, $2)",
                &[&request.url, &text],
            )?;
            // delete the request.
            db.execute("DELETE FROM request_ WHERE id = $1", &[&request._id])?;
        } else {
            println!("Waiting...");
            // Wait for a notification.
            let _ = db.notifications().blocking_iter().next();
        }
    }
}
