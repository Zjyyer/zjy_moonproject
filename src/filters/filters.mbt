///|
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

///|
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

///|
fn safe_string_slice(s : String, start : Int, end : Int) -> String {
  let len = s.length()
  let mut r_start = if start < 0 { len + start } else { start }
  let mut r_end = if end < 0 { len + end } else { end }
  if r_start < 0 {
    r_start = 0
  }
  if r_end > len {
    r_end = len
  }
  if r_start >= r_end || r_start >= len {
    return ""
  }
  s[r_start:r_end].to_owned()
}

///|
fn safe_array_slice(
  arr : Array[@value.Value],
  start : Int,
  end : Int,
) -> Array[@value.Value] {
  let len = arr.length()
  let mut r_start = if start < 0 { len + start } else { start }
  let mut r_end = if end < 0 { len + end } else { end }
  if r_start < 0 {
    r_start = 0
  }
  if r_end > len {
    r_end = len
  }
  if r_start >= r_end || r_start >= len {
    return []
  }
  let res = []
  let mut i = r_start
  while i < r_end {
    res.push(arr[i])
    i += 1
  }
  res
}

///|
fn string_replace(s : String, from_str : String, to_str : String) -> String {
  if from_str.length() == 0 {
    return s
  }
  let mut res = ""
  let mut i = 0
  let s_len = s.length()
  let f_len = from_str.length()
  while i < s_len {
    if i <= s_len - f_len {
      let mut match_found = true
      let mut j = 0
      while j < f_len {
        if s[i + j] != from_str[j] {
          match_found = false
          break
        }
        j += 1
      }
      if match_found {
        res = res + to_str
        i += f_len
        continue
      }
    }
    let c_u16 = s[i]
    let c = Int::unsafe_to_char(c_u16.to_int())
    res = res + c.to_string()
    i += 1
  }
  res
}

///|
fn string_truncate(s : String, max_len : Int) -> String {
  if s.length() <= max_len {
    s
  } else if max_len <= 0 {
    "..."
  } else {
    s[0:max_len].to_owned() + "..."
  }
}

///|
pub fn apply_filter(
  name : String,
  val : @value.Value,
  args : Array[@value.Value],
) -> Result[@value.Value, String] {
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
      @value.Value::VString(s) =>
        Ok(@value.Value::VNumber(s.length().to_double()))
      @value.Value::VArray(arr) =>
        Ok(@value.Value::VNumber(arr.length().to_double()))
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
      @value.Value::VString(s) =>
        match target {
          @value.Value::VString(sub) =>
            Ok(@value.Value::VBool(string_contains(s, sub)))
          _ => Err("Filter 'contains' on string expects a string argument")
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
  } else if name == "slice" {
    if args.length() < 1 || args.length() > 2 {
      return Err("Filter 'slice' expects 1 or 2 arguments")
    }
    let start = match args[0] {
      @value.Value::VNumber(n) => n.to_int()
      _ => return Err("Filter 'slice' start argument expects a number")
    }
    let end = if args.length() == 2 {
      match args[1] {
        @value.Value::VNumber(n) => n.to_int()
        _ => return Err("Filter 'slice' end argument expects a number")
      }
    } else {
      match val {
        @value.Value::VString(s) => s.length()
        @value.Value::VArray(arr) => arr.length()
        _ => 0
      }
    }
    match val {
      @value.Value::VString(s) =>
        Ok(@value.Value::VString(safe_string_slice(s, start, end)))
      @value.Value::VArray(arr) =>
        Ok(@value.Value::VArray(safe_array_slice(arr, start, end)))
      _ => Err("Filter 'slice' expects a string or array")
    }
  } else if name == "replace" {
    if args.length() != 2 {
      return Err("Filter 'replace' expects exactly 2 arguments")
    }
    let from_str = match args[0] {
      @value.Value::VString(s) => s
      _ => return Err("Filter 'replace' from argument expects a string")
    }
    let to_str = match args[1] {
      @value.Value::VString(s) => s
      _ => return Err("Filter 'replace' to argument expects a string")
    }
    match val {
      @value.Value::VString(s) =>
        Ok(@value.Value::VString(string_replace(s, from_str, to_str)))
      _ => Err("Filter 'replace' expects a string")
    }
  } else if name == "truncate" {
    if args.length() != 1 {
      return Err("Filter 'truncate' expects exactly 1 argument")
    }
    let max_len = match args[0] {
      @value.Value::VNumber(n) => n.to_int()
      _ => return Err("Filter 'truncate' length argument expects a number")
    }
    match val {
      @value.Value::VString(s) =>
        Ok(@value.Value::VString(string_truncate(s, max_len)))
      _ => Err("Filter 'truncate' expects a string")
    }
  } else if name == "abs" {
    match val {
      @value.Value::VNumber(n) => {
        let r = if n < 0.0 { -n } else { n }
        Ok(@value.Value::VNumber(r))
      }
      _ => Err("Filter 'abs' expects a number")
    }
  } else if name == "round" {
    match val {
      @value.Value::VNumber(n) => {
        let r = if n < 0.0 {
          (n - 0.5).to_int().to_double()
        } else {
          (n + 0.5).to_int().to_double()
        }
        Ok(@value.Value::VNumber(r))
      }
      _ => Err("Filter 'round' expects a number")
    }
  } else {
    Err("Unknown filter: " + name)
  }
}
