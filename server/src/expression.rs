pub struct Moment {
  pub time: i64,
}

pub enum At {
  Before(Moment),
  After(Moment),
  Closest(Moment),
  At(Moment),
  First,
  Last,
}

pub enum ArithBinaryOp {
  Add,
  Subtract,
  Multiply,
  Divide,
}

pub enum BoolOp {
  GT,
  LT,
  EQ,
}

pub enum Expression {
  Const(f64),
  Measurement { sensor: i64, at: At },
  MeasurementRange { sensor: i64, from: At, to: At },
  Abo(ArithBinaryOp, Box<Expression>, Box<Expression>),
  Bo(BoolOp, Box<Expression>, Box<Expression>),
}
