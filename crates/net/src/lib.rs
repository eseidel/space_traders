use anyhow::Result;

pub struct Request {
    pub id: i64,
    pub priority: i32,
    pub method: String,
    pub url: String,
    pub body: String,
}

impl Request {
    pub fn empty(url: &str, priority: i32) -> Request {
        Request {
            id: 0,
            priority,
            method: String::from("GET"),
            url: String::from(url),
            body: String::new(),
        }
    }
}

pub struct Response {
    pub id: i64,
    pub request_id: i64,
    pub status_code: i32,
    pub url: String,
    pub body: String,
}

pub enum Mode {
    Requestor,
    Responder,
}

pub fn connect_to_db(mode: Mode) -> Result<postgres::Client, postgres::Error> {
    let mut db = postgres::Client::connect(
        "postgresql://postgres:password@localhost/spacetraders",
        postgres::NoTls,
    )?;
    match mode {
        Mode::Responder => {
            db.batch_execute("LISTEN request_")?;
        }
        Mode::Requestor => {
            db.batch_execute("LISTEN response_")?;
        }
    }
    Ok(db)
}

pub fn queue_request(db: &mut postgres::Client, request: Request) -> Result<i64> {
    let id = db.query(
        "INSERT INTO request_ (url, body, priority, method) VALUES ($1, $2, $3, $4) RETURNING id",
        &[
            &request.url,
            &request.body,
            &request.priority,
            &request.method,
        ],
    )?;
    db.batch_execute("NOTIFY request_")?;
    Ok(id[0].get(0))
}

pub fn next_request(db: &mut postgres::Client) -> Result<Option<Request>> {
    let result = db.query_one(
        "SELECT id, priority, url, body FROM request_ ORDER BY priority DESC LIMIT 1",
        &[],
    );
    if let Ok(row) = result {
        Ok(Some(Request {
            id: row.get(0),
            priority: row.get(1),
            url: row.get(2),
            body: row.get(3),
            method: String::from("GET"),
        }))
    } else {
        Ok(None)
    }
}

pub fn delete_request(db: &mut postgres::Client, request_id: i64) -> Result<()> {
    db.execute("DELETE FROM request_ WHERE id = $1", &[&request_id])?;
    Ok(())
}

pub fn queue_response(db: &mut postgres::Client, response: Response) -> Result<()> {
    db.execute(
        "INSERT INTO response_ (request_id, status_code, url, body) VALUES ($1, $2, $3, $4)",
        &[
            &response.request_id,
            &response.status_code,
            &response.url,
            &response.body,
        ],
    )?;
    db.batch_execute("NOTIFY response_")?;
    Ok(())
}
