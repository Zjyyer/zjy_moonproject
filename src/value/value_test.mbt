test "Value::is_truthy" {
  assert_eq(Value::VNull.is_truthy(), false)
  assert_eq(Value::VBool(true).is_truthy(), true)
  assert_eq(Value::VBool(false).is_truthy(), false)
  assert_eq(Value::VNumber(1.0).is_truthy(), true)
  assert_eq(Value::VNumber(0.0).is_truthy(), false)
  assert_eq(Value::VString("hello").is_truthy(), true)
  assert_eq(Value::VString("").is_truthy(), false)
  assert_eq(Value::VArray([Value::VString("a")]).is_truthy(), true)
  assert_eq(Value::VArray([]).is_truthy(), false)
  
  let m : Map[String, Value] = {}
  assert_eq(Value::VObject(m).is_truthy(), false)
  m["key"] = Value::VString("val")
  assert_eq(Value::VObject(m).is_truthy(), true)
}
