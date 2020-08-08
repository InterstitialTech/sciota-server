extern crate serde_json;
#[macro_use]
extern crate serde_derive;

use serde_json::Value;
use std::collections::HashMap;
// #[tokio::main]
//  async fn main() -> Result<(), Box<dyn std::error::Error>> {
//   let resp = reqwest::get("https://httpbin.org/ip")
//     .await?
//     .json::<HashMap<String, String>>()
//     .await?;
//   println!("{:#?}", resp);
//   Ok(())
// }

// fn main() {
//     println!("Hello, world!");
// }
//
//

#[derive(Deserialize, Serialize, Debug)]
pub struct UserMessage {
  pub uid: String,
  pwd: String,
  what: String,
  data: Option<serde_json::Value>,
}

#[derive(Deserialize, Serialize, Debug, Clone)]
pub struct SaveMeasurement {
  value: f64,
  sensor: i64,
  measuredate: i64,
}

use reqwest::Error;
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
  let sm = SaveMeasurement {
    value: 5.0,
    sensor: 1,
    measuredate: 0,
  };

  let um = UserMessage {
    uid: "meh".to_string(),
    pwd: "meh".to_string(),
    what: "savemeasurement".to_string(),
    data: Some(serde_json::to_value(sm)?),
  };

  let client = reqwest::Client::new();
  let res = client
    .post("http://localhost:8002/user")
    .body(serde_json::to_string(&um)?)
    .send()
    .await?;

  println!("result: {:?}", res);

  Ok(())
}
