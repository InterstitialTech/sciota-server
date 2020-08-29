use config::Config;
use crypto_hash::{hex_digest, Algorithm};
use email;
use serde_json::Value;
use simple_error;
use sqldata;
use std::error::Error;
use std::path::Path;
use util;
use uuid::Uuid;

#[derive(Serialize, Deserialize)]
pub struct ServerResponse {
  pub what: String,
  pub content: Value,
}

#[derive(Clone)]
pub struct AppState {
  pub htmlstring: String,
  // pub publicmtb: Arc<RwLock<MetaTagBase>>,
}

#[derive(Deserialize, Debug)]
pub struct UserMessage {
  pub uid: String,
  pwd: String,
  what: String,
  data: Option<serde_json::Value>,
}

#[derive(Deserialize, Debug)]
pub struct PublicMessage {
  what: String,
  data: Option<serde_json::Value>,
}

#[derive(Deserialize, Debug)]
pub struct RegistrationData {
  email: String,
}

pub fn user_interface(config: &Config, msg: UserMessage) -> Result<ServerResponse, Box<dyn Error>> {
  info!("got a user message: {}", msg.what);
  if msg.what.as_str() == "register" {
    // do the registration thing.
    // user already exists?
    match sqldata::read_user(Path::new(&config.db), msg.uid.as_str()) {
      Ok(_) => {
        // err - user exists.
        Ok(ServerResponse {
          what: "user exists".to_string(),
          content: serde_json::Value::Null,
        })
      }
      Err(_) => {
        // user does not exist, which is what we want for a new user.
        // get email from 'data'.
        let msgdata = Option::ok_or(msg.data, "malformed registration data")?;
        let rd: RegistrationData = serde_json::from_value(msgdata)?;
        // TODO: make a real registration key
        let registration_key = Uuid::new_v4().to_string();
        let salt = util::salt_string();

        // write a user record.
        sqldata::new_user(
          Path::new(&config.db),
          msg.uid.clone(),
          hex_digest(
            Algorithm::SHA256,
            (msg.pwd + salt.as_str()).into_bytes().as_slice(),
          ),
          salt,
          rd.email.clone(),
          registration_key.clone().to_string(),
        )?;

        // send a registration email.
        email::send_registration(
          config.appname.as_str(),
          config.domain.as_str(),
          config.mainsite.as_str(),
          rd.email.as_str(),
          msg.uid.as_str(),
          registration_key.as_str(),
        )?;

        // notify the admin.
        email::send_registration_notification(
          config.appname.as_str(),
          config.domain.as_str(),
          "bburdettte@protonmail.com",
          rd.email.as_str(),
          msg.uid.as_str(),
          registration_key.as_str(),
        )?;

        Ok(ServerResponse {
          what: "registration sent".to_string(),
          content: serde_json::Value::Null,
        })
      }
    }
  } else {
    match sqldata::read_user(Path::new(&config.db), msg.uid.as_str()) {
      Err(_) => Ok(ServerResponse {
        what: "invalid user or pwd".to_string(),
        content: serde_json::Value::Null,
      }),
      Ok(userdata) => {
        // let userdata: User = serde_json::from_value(serde_json::from_str(udata.as_str())?)?;
        match userdata.registration_key {
          Some(_reg_key) => Ok(ServerResponse {
            what: "unregistered user".to_string(),
            content: serde_json::Value::Null,
          }),
          None => {
            if hex_digest(
              Algorithm::SHA256,
              (msg.pwd.clone() + userdata.salt.as_str())
                .into_bytes()
                .as_slice(),
            ) != userdata.hashwd
            {
              // don't distinguish between bad user id and bad pwd!
              Ok(ServerResponse {
                what: "invalid user or pwd".to_string(),
                content: serde_json::Value::Null,
              })
            } else {
              // finally!  processing messages as logged in user.
              user_interface_loggedin(&config, userdata.id, &msg)
            }
          }
        }
      }
    }
  }
}

fn user_interface_loggedin(
  config: &Config,
  uid: i64,
  msg: &UserMessage,
) -> Result<ServerResponse, Box<dyn Error>> {
  match msg.what.as_str() {
    "login" => Ok(ServerResponse {
      what: "logged in".to_string(),
      content: serde_json::Value::Null, // return api token that expires?
    }),
    "getdevicelisting" => {
      let entries = sqldata::devicelisting(Path::new(&config.db), uid)?;
      Ok(ServerResponse {
        what: "devicelisting".to_string(),
        content: serde_json::to_value(entries)?,
      })
    }
    "savedevice" => {
      let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
      let sz: sqldata::SaveDevice = serde_json::from_value(msgdata.clone())?;

      let deviceid = sqldata::save_device(&config.db.as_path(), uid, &sz)?;
      Ok(ServerResponse {
        what: "saveddevice".to_string(),
        content: serde_json::to_value(deviceid)?,
      })
    }
    "deletedevice" => {
      let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
      let deviceid: i64 = serde_json::from_value(msgdata.clone())?;

      sqldata::delete_device(&config.db.as_path(), uid, deviceid)?;
      Ok(ServerResponse {
        what: "deleteddevice".to_string(),
        content: serde_json::to_value(deviceid)?,
      })
    }
    "getsensorlisting" => {
      let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
      let deviceid: i64 = serde_json::from_value(msgdata.clone())?;

      let entries = sqldata::sensorlisting(Path::new(&config.db), uid, Some(deviceid))?;
      Ok(ServerResponse {
        what: "sensorlisting".to_string(),
        content: serde_json::to_value(entries)?, // return api token that expires?
      })
    }
    "savesensor" => {
      let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
      let sbe: sqldata::SaveSensor = serde_json::from_value(msgdata.clone())?;

      let s = sqldata::save_sensor(&config.db.as_path(), uid, &sbe)?;
      Ok(ServerResponse {
        what: "savedsensor".to_string(),
        content: serde_json::to_value(s)?,
      })
    }
    "savemeasurement" => {
      let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
      let m: sqldata::SaveMeasurement = serde_json::from_value(msgdata.clone())?;
      let s = sqldata::add_measurement(&config.db.as_path(), uid, &m)?;
      Ok(ServerResponse {
        what: "savedmeasurement".to_string(),
        content: serde_json::to_value(s)?,
      })
    }
    "getmeasurementlisting" => {
      let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
      let mq: sqldata::MeasurementQuery = serde_json::from_value(msgdata.clone())?;

      let entries = sqldata::measurement_listing(Path::new(&config.db), uid, mq.sensor)?;
      Ok(ServerResponse {
        what: "measurementlisting".to_string(),
        content: serde_json::to_value(entries)?, // return api token that expires?
      })
    }
    /*
        "getzklisting" => {
          let entries = sqldata::zklisting(Path::new(&config.db), uid)?;
          Ok(ServerResponse {
            what: "zklisting".to_string(),
            content: serde_json::to_value(entries)?, // return api token that expires?
          })
        }
        "getzk" => {
          let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
          let id: i64 = serde_json::from_value(msgdata.clone())?;

          let zk = sqldata::read_zk(Path::new(&config.db), id)?;
          Ok(ServerResponse {
            what: "zk".to_string(),
            content: serde_json::to_value(zk)?,
          })
        }
        "getzknote" => {
          let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
          let id: i64 = serde_json::from_value(msgdata.clone())?;

          let note = sqldata::read_zknote(Path::new(&config.db), id)?;
          Ok(ServerResponse {
            what: "zknote".to_string(),
            content: serde_json::to_value(note)?,
          })
        }
        "deletezknote" => {
          let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
          let id: i64 = serde_json::from_value(msgdata.clone())?;

          sqldata::delete_zknote(Path::new(&config.db), uid, id)?;
          Ok(ServerResponse {
            what: "deletedzknote".to_string(),
            content: serde_json::to_value(id)?,
          })
        }
    */
    wat => Err(Box::new(simple_error::SimpleError::new(format!(
      "invalid 'what' code:'{}'",
      wat
    )))),
  }
}

// public json msgs don't require login.
pub fn public_interface(
  config: &Config,
  msg: PublicMessage,
) -> Result<ServerResponse, Box<dyn Error>> {
  info!("process_public_json, what={}", msg.what.as_str());
  match msg.what.as_str() {
    /*    "getzknote" => {
      let msgdata = Option::ok_or(msg.data.as_ref(), "malformed json data")?;
      let id: i64 = serde_json::from_value(msgdata.clone())?;

      let note = sqldata::read_zknote(&config.db.as_path(), id)?;
      Ok(ServerResponse {
        what: "zknote".to_string(),
        content: serde_json::to_value(note)?,
      })
    }*/
    wat => Err(Box::new(simple_error::SimpleError::new(format!(
      "invalid 'what' code:'{}'",
      wat
    )))),
  }
}
