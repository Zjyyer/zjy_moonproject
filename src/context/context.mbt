pub struct Context {
  vars : Map[String, @value.Value]
}

pub fn Context::new() -> Context {
  { vars: Map::of([]) }
}

pub fn Context::set(self : Context, key : String, val : @value.Value) -> Unit {
  self.vars.set(key, val)
}

pub fn Context::get(self : Context, key : String) -> Option[@value.Value] {
  self.vars.get(key)
}
