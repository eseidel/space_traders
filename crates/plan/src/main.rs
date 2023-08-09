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
    let res = register(&conf, Some(reg_req))
        .await
        .expect("Error registering agent");
    println!("{:#?}", res);
    // Update Config with Agent Token
    conf.bearer_access_token = Some(res.data.token);

    // Get Agent Details to Confirm Working
    let res = get_my_agent(&conf).await.expect("Error getting agent");
    println!("{:#?}", res);
    // Print Symbol
    println!("My Symbol: {:#?}", res.data.symbol);

    Ok(())
}
