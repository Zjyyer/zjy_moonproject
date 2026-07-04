fn format_val(v : @value.Value) -> String {
  match v {
    @value.Value::VNull => ""
    @value.Value::VBool(true) => "true"
    @value.Value::VBool(false) => "false"
    @value.Value::VNumber(n) => n.to_string()
    @value.Value::VString(s) => s
    _ => "<object>"
  }
}

fn string_contains(s : String, sub : String) -> Bool {
  if sub.length() == 0 {
    return true
  }
  if s.length() < sub.length() {
    return false
  }
  let mut i = 0
  let limit = s.length() - sub.length()
  while i <= limit {
    let mut j = 0
    let mut match_found = true
    while j < sub.length() {
      if s[i + j] != sub[j] {
        match_found = false
        break
      }
      j += 1
    }
    if match_found {
      return true
    }
    i += 1
  }
  false
}

pub fn apply_filter(name : String, val : @value.Value, args : Array[@value.Value]) -> Result[@value.Value, String] {
  if name == "upper" {
    match val {
      @value.Value::VString(s) => {
        let mut res = ""
        let mut i = 0
        while i < s.length() {
          let c_u16 = s[i]
          let c = Int::unsafe_to_char(c_u16.to_int())
          let code = c.to_int()
          if code >= 97 && code <= 122 {
            let uc = Int::unsafe_to_char(code - 32)
            res = res + uc.to_string()
          } else {
            res = res + c.to_string()
          }
          i += 1
        }
        Ok(@value.Value::VString(res))
      }
      _ => Err("Filter 'upper' expects a string")
    }
  } else if name == "lower" {
    match val {
      @value.Value::VString(s) => {
        let mut res = ""
        let mut i = 0
        while i < s.length() {
          let c_u16 = s[i]
          let c = Int::unsafe_to_char(c_u16.to_int())
          let code = c.to_int()
          if code >= 65 && code <= 90 {
            let lc = Int::unsafe_to_char(code + 32)
            res = res + lc.to_string()
          } else {
            res = res + c.to_string()
          }
          i += 1
        }
        Ok(@value.Value::VString(res))
      }
      _ => Err("Filter 'lower' expects a string")
    }
  } else if name == "length" {
    match val {
      @value.Value::VString(s) => Ok(@value.Value::VNumber(s.length().to_double()))
      @value.Value::VArray(arr) => Ok(@value.Value::VNumber(arr.length().to_double()))
      _ => Err("Filter 'length' expects a string or array")
    }
  } else if name == "default" {
    if args.length() != 1 {
      return Err("Filter 'default' expects exactly 1 argument")
    }
    match val {
      @value.Value::VNull => Ok(args[0])
      @value.Value::VString("") => Ok(args[0])
      _ => Ok(val)
    }
  } else if name == "join" {
    let sep = if args.length() > 0 {
      match args[0] {
        @value.Value::VString(s) => s
        _ => return Err("Filter 'join' separator argument expects a string")
      }
    } else {
      ""
    }
    match val {
      @value.Value::VArray(arr) => {
        let mut res = ""
        let mut i = 0
        while i < arr.length() {
          if i > 0 {
            res = res + sep
          }
          res = res + format_val(arr[i])
          i += 1
        }
        Ok(@value.Value::VString(res))
      }
      _ => Err("Filter 'join' expects an array")
    }
  } else if name == "contains" {
    if args.length() != 1 {
      return Err("Filter 'contains' expects exactly 1 argument")
    }
    let target = args[0]
    match val {
      @value.Value::VString(s) => {
        match target {
          @value.Value::VString(sub) => Ok(@value.Value::VBool(string_contains(s, sub)))
          _ => Err("Filter 'contains' on string expects a string argument")
        }
      }
      @value.Value::VArray(arr) => {
        let mut found = false
        let len = arr.length()
        let mut i = 0
        while i < len {
          if arr[i] == target {
            found = true
            break
          }
          i += 1
        }
        Ok(@value.Value::VBool(found))
      }
      _ => Err("Filter 'contains' expects a string or array")
    }
  } else {
    Err("Unknown filter: " + name)
  }
}
