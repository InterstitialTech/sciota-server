use rusqlite::{params, Connection};
use serde_json;
use std::convert::TryInto;
use std::error::Error;
use std::path::Path;
use std::time::SystemTime;

#[derive(Serialize, Debug, Clone)]
pub struct Device {
  id: i64,
  user: i64,
  name: String,
  description: String,
  createdate: i64,
  changeddate: i64,
}

#[derive(Deserialize, Debug, Clone)]
pub struct SaveDevice {
  id: Option<i64>,
  name: String,
  description: String,
}

#[derive(Serialize, Debug, Clone)]
pub struct Sensor {
  id: i64,
  name: String,
  description: String,
  createdate: i64,
  changeddate: i64,
}

#[derive(Deserialize, Debug, Clone)]
pub struct SaveSensor {
  id: Option<i64>,
  name: String,
  description: String,
}

#[derive(Serialize, Debug, Clone)]
pub struct Measurement {
  id: i64,
  value: f64,
  sensor: i64,
  createdate: i64,
  measuredate: i64,
}

#[derive(Serialize, Debug, Clone)]
pub struct SaveMeasurement {
  value: f64,
  sensor: i64,
  measuredate: i64,
}

#[derive(Deserialize, Serialize, Debug)]
pub struct User {
  pub id: i64,
  pub name: String,
  pub hashwd: String,
  pub salt: String,
  pub email: String,
  pub registration_key: Option<String>,
}

pub fn dbinit(dbfile: &Path) -> rusqlite::Result<()> {
  let conn = Connection::open(dbfile)?;

  conn.execute(
    "CREATE TABLE user (
                id          INTEGER NOT NULL PRIMARY KEY,
                name        TEXT NOT NULL UNIQUE,
                hashwd      TEXT NOT NULL,
                salt        TEXT NOT NULL,
                email       TEXT NOT NULL,
                registration_key  TEXT,
                createdate  INTEGER NOT NULL
                )",
    params![],
  )?;

  conn.execute(
    "CREATE TABLE sensor (
                id            INTEGER NOT NULL PRIMARY KEY,
                device 				INTEGER NOT NULL,
                name          TEXT NOT NULL,
                description   TEXT NOT NULL,
                createdate    INTEGER NOT NULL,
                changeddate   INTEGER NOT NULL,
                FOREIGN KEY(device) REFERENCES device(id)
                )",
    params![],
  )?;

  conn.execute(
    "CREATE TABLE device (
                id            INTEGER NOT NULL PRIMARY KEY,
                user 					INTEGER NOT NULL,
                name          TEXT NOT NULL,
                description   TEXT NOT NULL,
                createdate    INTEGER NOT NULL,
                changeddate   INTEGER NOT NULL,
                FOREIGN KEY(user) REFERENCES user(id)
                )",
    params![],
  )?;

  conn.execute(
    "CREATE TABLE measurement (
                id            INTEGER NOT NULL PRIMARY KEY,
                sensor        INTEGER NOT NULL
                value 				REAL NOT NULL,
                measuredate   INTEGER NOT NULL,
                createdate    INTEGER NOT NULL,
                FOREIGN KEY(user) REFERENCES user(id)
                )",
    params![],
  )?;

  Ok(())
}

pub fn now() -> Result<i64, Box<dyn Error>> {
  let nowsecs = SystemTime::now()
    .duration_since(SystemTime::UNIX_EPOCH)
    .map(|n| n.as_secs())?;
  let s: i64 = nowsecs.try_into()?;
  Ok(s * 1000)
}

// --------------------------------------------------------------------------------------
// user CRUD

pub fn add_user(dbfile: &Path, name: &str, hashwd: &str) -> Result<i64, Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  let nowi64secs = now()?;

  println!("adding user: {}", name);
  let wat = conn.execute(
    "INSERT INTO user (name, hashwd, createdate)
                VALUES (?1, ?2, ?3)",
    params![name, hashwd, nowi64secs],
  )?;

  println!("wat: {}", wat);

  Ok(conn.last_insert_rowid())
}

pub fn read_user(dbfile: &Path, name: &str) -> Result<User, Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  let user = conn.query_row(
    "SELECT id, hashwd, salt, email, registration_key
      FROM user WHERE name = ?1",
    params![name],
    |row| {
      Ok(User {
        id: row.get(0)?,
        name: name.to_string(),
        hashwd: row.get(1)?,
        salt: row.get(2)?,
        email: row.get(3)?,
        registration_key: row.get(4)?,
      })
    },
  )?;

  Ok(user)
}

pub fn update_user(dbfile: &Path, user: &User) -> Result<(), Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  conn.execute(
    "UPDATE user SET name = ?1, hashwd = ?2, salt = ?3, email = ?4, registration_key = ?5
     WHERE id = ?6",
    params![
      user.name,
      user.hashwd,
      user.salt,
      user.email,
      user.registration_key,
      user.id
    ],
  )?;

  Ok(())
}

pub fn new_user(
  dbfile: &Path,
  name: String,
  hashwd: String,
  salt: String,
  email: String,
  registration_key: String,
) -> Result<i64, Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  let now = now()?;

  let user = conn.execute(
    "INSERT INTO user (name, hashwd, salt, email, registration_key, createdate)
      VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
    params![name, hashwd, salt, email, registration_key, now],
  )?;

  Ok(conn.last_insert_rowid())
}

// --------------------------------------------------------------------------------------
// device CRUD

pub fn save_device(
  dbfile: &Path,
  uid: i64,
  savedevice: &SaveDevice,
) -> Result<i64, Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  let now = now()?;

  match savedevice.id {
    Some(id) => {
      println!("updating device: {}", savedevice.name);

      // TODO ensure user auth here.

      conn.execute(
        "UPDATE device SET name = ?1, description = ?2, changeddate = ?3
         WHERE id = ?4",
        params![savedevice.name, savedevice.description, now, savedevice.id],
      )?;
      Ok(id)
    }
    None => {
      println!("adding device: {}", savedevice.name);
      conn.execute(
        "INSERT INTO device (name, description, createdate, changeddate)
         VALUES (?1, ?2, ?3, ?4)",
        params![savedevice.name, savedevice.description, now, now],
      )?;

      let deviceid = conn.last_insert_rowid();

      conn.execute(
        "INSERT INTO devicemember (device, user)
         VALUES (?1, ?2)",
        params![deviceid, uid],
      )?;

      Ok(deviceid)
    }
  }
}

pub fn read_device(dbfile: &Path, id: i64) -> Result<Device, Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  let rbe = conn.query_row(
    "SELECT name, description, createdate, changeddate
      FROM device WHERE id = ?1",
    params![id],
    |row| {
      Ok(Device {
        id: id,
        name: row.get(0)?,
        description: row.get(1)?,
        user: row.get(2)?,
        createdate: row.get(3)?,
        changeddate: row.get(4)?,
      })
    },
  )?;

  Ok(rbe)
}

pub fn delete_device(dbfile: &Path, uid: i64, id: i64) -> Result<(), Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  // TODO: delete all sensors from this device also.
  // only delete when user is in the device
  conn.execute(
    "DELETE FROM device WHERE id = ?1 and user = ?2",
    params![id, uid],
  )?;
  Ok(())
}

pub fn devicelisting(dbfile: &Path, user: i64) -> rusqlite::Result<Vec<Device>> {
  let conn = Connection::open(dbfile)?;

  let mut pstmt = conn.prepare(
    "SELECT id, name, description, user, createdate, changeddate
      FROM device
      where devic.user = ?1",
  )?;

  let rec_iter = pstmt.query_map(params![user], |row| {
    Ok(Device {
      id: row.get(0)?,
      name: row.get(1)?,
      description: row.get(2)?,
      user: row.get(3)?,
      createdate: row.get(4)?,
      changeddate: row.get(5)?,
    })
  })?;

  let mut pv = Vec::new();

  for rsrec in rec_iter {
    match rsrec {
      Ok(rec) => {
        pv.push(rec);
      }
      Err(_) => (),
    }
  }

  Ok(pv)
}

// --------------------------------------------------------------------------------------
// sensor CRUD

pub fn save_sensor(
  dbfile: &Path,
  uid: i64,
  device: i64,
  sensor: &SaveSensor,
) -> Result<i64, Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  let now = now()?;

  // TODO ensure user auth here.

  match sensor.id {
    Some(id) => {
      println!("updating sensor: {}", sensor.name);
      conn.execute(
        "UPDATE sensor SET name = ?1, description = ?2, changeddate = ?3
         WHERE id = ?4",
        params![sensor.name, sensor.description, now, sensor.id],
      )?;
      Ok(id)
    }
    None => {
      println!("adding sensor: {}", sensor.name);
      conn.execute(
        "INSERT INTO sensor (name, description, createdate, changeddate)
         VALUES (?1, ?2, ?3, ?4, ?5)",
        params![sensor.name, sensor.description, now, now],
      )?;

      Ok(conn.last_insert_rowid())
    }
  }
}

pub fn read_sensor(dbfile: &Path, id: i64) -> Result<Sensor, Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  let rbe = conn.query_row(
    "SELECT name, description, createdate, changeddate
      FROM sensor WHERE id = ?1",
    params![id],
    |row| {
      Ok(Sensor {
        id: id,
        name: row.get(0)?,
        description: row.get(1)?,
        createdate: row.get(3)?,
        changeddate: row.get(4)?,
      })
    },
  )?;

  Ok(rbe)
}
pub fn delete_sensor(dbfile: &Path, uid: i64, sensorid: i64) -> Result<(), Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  // only delete when user is in the zk
  conn.execute(
    "DELETE FROM sensor WHERE id = ?1 
      AND device IN (SELECT id FROM device WHERE user = ?2)",
    params![sensorid, uid],
  )?;

  Ok(())
}

pub fn sensorlisting(
  dbfile: &Path,
  user: i64,
  device: Option<i64>,
) -> rusqlite::Result<Vec<Sensor>> {
  let conn = Connection::open(dbfile)?;

  let mut pv = Vec::new();
  match device {
    Some(dev) =>
    // check for user on device.
    {
      let mut pstmt = conn.prepare(
        "SELECT id, name, description, createdate, changeddate
              FROM sensor where device = ?1
              and device in (SELECT id FROM device WHERE user = ?2)",
      )?;
      let rec_iter = pstmt.query_map(params![dev, user], |row| {
        Ok(Sensor {
          id: row.get(0)?,
          name: row.get(1)?,
          description: row.get(2)?,
          createdate: row.get(3)?,
          changeddate: row.get(4)?,
        })
      })?;

      for rsrec in rec_iter {
        match rsrec {
          Ok(rec) => {
            pv.push(rec);
          }
          Err(_) => (),
        }
      }
    }
    None => {
      let mut pstmt = conn.prepare(
        "SELECT id, name, description, createdate, changeddate
              FROM sensor where device IN
                (SELECT id FROM device WHERE user = ?1)",
      )?;
      let rec_iter = pstmt.query_map(params![user], |row| {
        Ok(Sensor {
          id: row.get(0)?,
          name: row.get(1)?,
          description: row.get(2)?,
          createdate: row.get(3)?,
          changeddate: row.get(4)?,
        })
      })?;

      for rsrec in rec_iter {
        match rsrec {
          Ok(rec) => {
            pv.push(rec);
          }
          Err(_) => (),
        }
      }
    }
  };

  Ok(pv)
}

// --------------------------------------------------------------------------------------
// measurement CRUD

pub fn add_measurement(
  dbfile: &Path,
  uid: i64,
  measurement: &SaveMeasurement,
) -> Result<i64, Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  let now = now()?;

  println!("adding measurement: {}", measurement.value);
  conn.execute(
    "INSERT INTO measurement (sensor, value, measuredate, createdate)
     VALUES (?1, ?2, ?3, ?4)",
    params![
      measurement.sensor,
      measurement.value,
      measurement.measuredate,
      now
    ],
  )?;

  Ok(conn.last_insert_rowid())
}

pub fn measurement_listing(
  dbfile: &Path,
  uid: i64,
  sensor: i64,
) -> Result<Vec<Measurement>, Box<dyn Error>> {
  let conn = Connection::open(dbfile)?;

  // TODO: user owns this sensor?
  let mut pstmt = conn.prepare(
    "SELECT id, value, sensor, measuredate, createdate
            FROM measurement where sensor = ?1",
  )?;

  let mut rec_iter = pstmt.query_map(params![sensor], |row| {
    Ok(Measurement {
      id: row.get(0)?,
      value: row.get(1)?,
      sensor: sensor,
      measuredate: row.get(2)?,
      createdate: row.get(2)?,
    })
  })?;

  let mut pv = Vec::new();

  for rsrec in rec_iter {
    match rsrec {
      Ok(rec) => {
        pv.push(rec);
      }
      Err(_) => (),
    }
  }

  Ok(pv)
}
