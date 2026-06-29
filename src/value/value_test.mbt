test "Value::is_truthy" {
  assert_eq!(Null.is_truthy(), false)
  assert_eq!(Bool(true).is_truthy(), true)
  assert_eq!(Bool(false).is_truthy(), false)
  assert_eq!(Number(1.0).is_truthy(), true)
  assert_eq!(Number(0.0).is_truthy(), false)
  assert_eq!(String("hello").is_truthy(), true)
  assert_eq!(String("").is_truthy(), false)
  assert_eq!(Array([String("a")]).is_truthy(), true)
  assert_eq!(Array([]).is_truthy(), false)
  
  let m : Map[String, Value] = {}
  assert_eq!(Object(m).is_truthy(), false)
  m["key"] = String("val")
  assert_eq!(Object(m).is_truthy(), true)
}
