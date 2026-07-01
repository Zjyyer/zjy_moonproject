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
  } else {
    Err("Unknown filter: " + name)
  }
}
