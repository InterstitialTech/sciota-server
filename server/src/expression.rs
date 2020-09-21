#[derive(Deserialize, Serialize, Debug, Clone)]
pub struct Moment {
  pub time: i64,
}

#[derive(Deserialize, Serialize, Debug, Clone)]
pub enum At {
  Before(Moment),
  After(Moment),
  Closest(Moment),
  At(Moment),
  First,
  Last,
}

#[derive(Deserialize, Serialize, Debug, Clone)]
pub enum ArithOp {
  Add,
  Subtract,
  Multiply,
  Divide,
}

#[derive(Deserialize, Serialize, Debug, Clone)]
pub enum BoolOp {
  GT,
  LT,
  EQ,
}

#[derive(Deserialize, Serialize, Debug, Clone)]
pub enum Expression {
  Const(f64),
  Measurement { sensor: i64, at: At },
  MeasurementRange { sensor: i64, from: At, to: At },
  Abo(ArithOp, Vec<Box<Expression>>),
  Bo(BoolOp, Vec<Box<Expression>>),
}

#[derive(Deserialize, Serialize, Debug, Clone)]
pub enum MeasureRequest {
  Single { sensor: i64, at: At },
  Range { sensor: i64, from: At, to: At },
}

pub fn eval_for_measure_requests(exp: &Expression) -> Vec<MeasureRequest> {
  match exp {
    Expression::Const(_) => vec![],
    Expression::Measurement { sensor, at } => vec![MeasureRequest::Single {
      sensor: sensor.clone(),
      at: at.clone(),
    }],
    Expression::MeasurementRange { sensor, from, to } => vec![MeasureRequest::Range {
      sensor: sensor.clone(),
      from: from.clone(),
      to: to.clone(),
    }],
    Expression::Abo(op, exps) => {
      let mut v = Vec::new();
      for exp in exps {
        let mut v2 = eval_for_measure_requests(exp);
        v.append(&mut v2);
      }
      v
    }
    Expression::Bo(op, exps) => {
      let mut v = Vec::new();
      for exp in exps {
        let mut v2 = eval_for_measure_requests(exp);
        v.append(&mut v2);
      }
      v
    }
  }
}

pub struct MeasureStore {}
