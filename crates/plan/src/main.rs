// Get the list of ships.
// Get the agent (for credits).

use spacedust::apis::agents_api::get_my_agent;
use spacedust::apis::configuration::Configuration;
use spacedust::apis::default_api::register;
use spacedust::models::register_request::RegisterRequest;
use spacedust::models::FactionSymbols;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Create Configuration
    let mut conf = Configuration::new();

    // Create Register Request
    let reg_req = RegisterRequest::new(FactionSymbols::Cosmic, "ESEIDEL-RUST".to_string());

    // Register Agent
    let register_response = register(&conf, Some(reg_req)).await;

    match register_response {
        Ok(res) => {
            println!("{:#?}", res);
            // Update Config with Agent Token
            conf.bearer_access_token = Some(res.data.token);
        }
        Err(err_res) => {
            panic!("{:#?}", err_res);
        }
    }

    // Get Agent Details to Confirm Working
    match get_my_agent(&conf).await {
        Ok(res) => {
            println!("{:#?}", res);
            // Print Symbol
            println!("My Symbol: {:#?}", res.data.symbol);
        }
        Err(err_res) => {
            panic!("{:#?}", err_res);
        }
    }

    Ok(())
}
