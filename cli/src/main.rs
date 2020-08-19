extern crate serde_json;
#[macro_use]
extern crate serde_derive;
extern crate clap;

use clap::{Arg, App, SubCommand};
use reqwest;
use serde_json::Value;
use std::collections::HashMap;
use std::time::SystemTime;
use std::convert::TryInto;
use std::fs::File;
use std::io::Read;
use std::io::Write;
use std::path::Path;

//  ./target/debug/cli "http://localhost:8002/user" 1 5.1

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

pub fn now() -> Result<i64, Box<dyn std::error::Error>> {
  let nowsecs = SystemTime::now()
    .duration_since(SystemTime::UNIX_EPOCH)
    .map(|n| n.as_millis())?;
  let s: i64 = nowsecs.try_into()?;
  Ok(s)
}

pub fn write_string(file_name: &str, text: &str) -> Result<usize, Box<dyn std::error::Error>> {
  let path = &Path::new(&file_name);
  let mut inf = File::create(path)?;
  Ok(inf.write(text.as_bytes())?)
}


#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {

  let matches = App::new("measurelog cli - http")
                          .version("1.0")
                          .author("Ben Burdette")
                          .about("sends a measurement to the measurelog server")
                          .arg(Arg::with_name("server")
                               .help("server address")
                               .required(true)
                               .index(1))
                          .arg(Arg::with_name("sensor")
                               .help("sensor id")
                               .required(true)
                               .index(2))
                          .arg(Arg::with_name("value")
                               .help("value")
                               .required(true)
                               .index(3))
                          .get_matches();

  let sm = SaveMeasurement {
    value: matches.value_of("value").ok_or("bad value")?.parse::<f64>()?,
    sensor: matches.value_of("sensor").ok_or("wat")?.parse::<i64>()?,
    measuredate: now()?,
  };

  let um = UserMessage {
    uid: "meh".to_string(),
    pwd: "meh".to_string(),
    what: "savemeasurement".to_string(),
    data: Some(serde_json::to_value(sm)?),
  };

  write_string("message.txt", serde_json::to_string(&um)?.as_str())?;

  write_string("message-pretty.txt", serde_json::to_string_pretty(&um)?.as_str())?;

  let client = reqwest::Client::new();
  let res = client
    .post(matches.value_of("server").ok_or("wat")?)
    .json(&um)
    .send()
    .await?;

  println!("result: {:?}", res);

  Ok(())
}
