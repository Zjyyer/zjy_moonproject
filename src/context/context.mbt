///|
pub struct Context {
  vars : Map[String, @value.Value]
  parent : Context?
}

///|
pub fn Context::new() -> Context {
  { vars: Map([]), parent: None }
}

///|
pub fn Context::new_child(parent : Context) -> Context {
  { vars: Map([]), parent: Some(parent) }
}

///|
pub fn Context::set(self : Context, key : String, val : @value.Value) -> Unit {
  self.vars.set(key, val)
}

///|
pub fn Context::get(self : Context, key : String) -> @value.Value? {
  match self.vars.get(key) {
    Some(v) => Some(v)
    None =>
      match self.parent {
        Some(p) => p.get(key)
        None => None
      }
  }
}
