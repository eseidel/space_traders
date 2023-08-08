#[macro_use]
extern crate rocket;
use rocket::request::Request;
use rocket::response;
use rocket::response::Responder;
use rocket::serde::json::Json;
use rocket::serde::Deserialize;

// Parse the json request and reply with the provided body and headers.
// The request is a json object with the following fields:
// - body: the body to send
// - headers: an object of headers to send

#[derive(Deserialize, FromForm)]
#[serde(crate = "rocket::serde")]
struct Header {
    name: String,
    value: String,
}

#[derive(Deserialize, FromForm)]
#[serde(crate = "rocket::serde")]
struct Call {
    headers: Vec<Header>,
    body: String,
}

impl<'r> Responder<'r, 'static> for Call {
    fn respond_to(self, _: &'r Request<'_>) -> response::Result<'static> {
        let mut response = rocket::Response::new();
        response.set_raw_header("Content-Type", "application/json");
        for header in self.headers {
            response.set_raw_header(header.name, header.value);
        }
        response.set_sized_body(self.body.len(), std::io::Cursor::new(self.body));
        Ok(response)
    }
}

#[get("/<_..>", format = "json", data = "<call>")]
fn everything(call: Json<Call>) -> Call {
    call.into_inner()
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/", routes![everything])
}
