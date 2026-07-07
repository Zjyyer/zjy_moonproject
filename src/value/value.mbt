/// `Value` represents the dynamic data types supported in the template.
pub(all) enum Value {
  VNull
  VBool(Bool)
  VNumber(Double)
  VString(String)
  VArray(Array[Value])
  VObject(Map[String, Value])
} derive(Eq, Debug)

pub impl Show for Value with output(self, logger) {
  self.output(logger)
}

/// Check if a `Value` is considered truthy.
///
/// In MoonTera:
/// - `VNull` is false
/// - `VBool(false)` is false
/// - `VNumber(0.0)` is false, all other numbers are true
/// - Empty `VString`, `VArray`, `VObject` are false
pub fn Value::is_truthy(self : Value) -> Bool {
  match self {
    VNull => false
    VBool(b) => b
    VNumber(n) => n != 0.0
    VString(s) => s.length() > 0
    VArray(arr) => arr.length() > 0
    VObject(obj) => obj.length() > 0
  }
}
