pub struct Context {
  vars : Map[String, @value.Value]
  parent : Option[Context]
}

pub fn Context::new() -> Context {
  { vars: Map::of([]), parent: None }
}

pub fn Context::new_child(parent : Context) -> Context {
  { vars: Map::of([]), parent: Some(parent) }
}

pub fn Context::set(self : Context, key : String, val : @value.Value) -> Unit {
  self.vars.set(key, val)
}

pub fn Context::get(self : Context, key : String) -> Option[@value.Value] {
  match self.vars.get(key) {
    Some(v) => Some(v)
    None => {
      match self.parent {
        Some(p) => p.get(key)
        None => None
      }
    }
  }
}
