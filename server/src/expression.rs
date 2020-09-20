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
pub enum ArithBinaryOp {
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
  Abo(ArithBinaryOp, Box<Expression>, Box<Expression>),
  Bo(BoolOp, Box<Expression>, Box<Expression>),
}

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
    Expression::Abo(op, exp1, exp2) => {
      let mut v = eval_for_measure_requests(exp2);
      let mut v2 = eval_for_measure_requests(exp1);
      v2.append(&mut v);
      v2
    }
    Expression::Bo(op, exp1, exp2) => {
      let mut v = eval_for_measure_requests(exp2);
      let mut v2 = eval_for_measure_requests(exp1);
      v2.append(&mut v);
      v2
    }
  }
}
