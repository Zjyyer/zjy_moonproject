/// `Value` represents the dynamic data types supported in the template.
public enum Value {
  Null
  Bool(Bool)
  Number(Double)
  String(String)
  Array(Array[Value])
  Object(Map[String, Value])
} derive(Eq, Show)

/// Check if a `Value` is considered truthy.
///
/// In MoonTera:
/// - `Null` is false
/// - `Bool(false)` is false
/// - `Number(0.0)` is false, all other numbers are true
/// - Empty `String`, `Array`, `Object` are false
public fn is_truthy(self : Value) -> Bool {
  match self {
    Null => false
    Bool(b) => b
    Number(n) => n != 0.0
    String(s) => s.length() > 0
    Array(arr) => arr.length() > 0
    Object(obj) => obj.size() > 0
  }
}
