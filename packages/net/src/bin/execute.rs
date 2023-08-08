use anyhow::Result;
use postgres::fallible_iterator::FallibleIterator;
use serde::Serialize;

use net::*;

#[derive(Serialize)]
struct Header {
    name: String,
    value: String,
}

#[derive(Serialize)]
struct Call {
    headers: Vec<Header>,
    body: String,
}

// "x-ratelimit-reset" is an iso8601 timestamp of the utc (server) time
// when the ratelimit will reset.
fn get_reset_time(headers: &reqwest::header::HeaderMap) -> Option<chrono::DateTime<chrono::Utc>> {
    let reset_time = headers.get("x-ratelimit-reset")?;
    let reset_time = reset_time.to_str().ok()?;
    let reset_time = chrono::DateTime::parse_from_rfc3339(reset_time).ok()?;
    let reset_time = reset_time.with_timezone(&chrono::Utc);
    Some(reset_time)
}

fn get_time_until_reset(headers: &reqwest::header::HeaderMap) -> chrono::Duration {
    match get_reset_time(headers) {
        Some(reset_time) => reset_time - chrono::Utc::now(),
        None => chrono::Duration::seconds(10),
    }
}

fn main() -> Result<()> {
    let mut db = connect_to_db(Mode::Responder)?;

    let requests_per_second = 1;
    let time_between_requests = std::time::Duration::from_millis(1000 / requests_per_second);
    let net = reqwest::blocking::Client::new();
    let mut next_request_time = std::time::Instant::now();

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
        let next = next_request(&mut db)?;
        if let Some(request) = next {
            println!("{} {} with {}", request.priority, request.url, request.body);
            let body = serde_json::to_string(&Call {
                headers: vec![],
                body: request.body,
            })?;
            let res = net.get("http://localhost:8000/").body(body).send()?;

            // Handle ratelimiting
            // If 429, then parse out x-ratelimit-reset header
            // and sleep until that time.
            if res.status() == reqwest::StatusCode::TOO_MANY_REQUESTS {
                let time_until_reset = get_time_until_reset(res.headers());
                println!("Sleeping for {:?}", time_until_reset);
                std::thread::sleep(time_until_reset.to_std()?);
            }

            let text = res.text()?;
            println!("{}", text);
            // post the result.
            queue_response(&mut db, request.id, &request.url, &text)?;
            delete_request(&mut db, request.id)?;
        } else {
            println!("Waiting...");
            // Wait for a notification.
            let _ = db.notifications().blocking_iter().next();
        }
    }
}
