enum LexMode {
  Text
  InVariable
  InBlock
} derive(Eq)

pub struct Lexer {
  input : String
  mut pos : Int
  mut mode : LexMode
}

pub fn Lexer::new(input : String) -> Lexer {
  { input, pos: 0, mode: Text }
}

fn Lexer::char_at(self : Lexer, index : Int) -> Char {
  Int::unsafe_to_char(self.input[index].to_int())
}

fn Lexer::peek(self : Lexer) -> Option[Char] {
  if self.pos < self.input.length() {
    Some(self.char_at(self.pos))
  } else {
    None
  }
}

fn Lexer::peek_next(self : Lexer) -> Option[Char] {
  if self.pos + 1 < self.input.length() {
    Some(self.char_at(self.pos + 1))
  } else {
    None
  }
}

fn Lexer::consume(self : Lexer) -> Option[Char] {
  if self.pos < self.input.length() {
    let c = self.char_at(self.pos)
    self.pos += 1
    Some(c)
  } else {
    None
  }
}

fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while true {
    match self.peek() {
      Some(' ') | Some('\t') | Some('\n') | Some('\r') => {
        let _ = self.consume()
      }
      _ => break
    }
  }
}

fn is_ident_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

fn is_ident_char(c : Char) -> Bool {
  is_ident_start(c) || (c >= '0' && c <= '9')
}

fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

fn parse_double(s : String) -> Double {
  let mut val = 0.0
  let mut decimal_divider = 1.0
  let mut in_decimal = false
  let mut i = 0
  let mut sign = 1.0
  if s.length() > 0 && s[0] == '-' {
    sign = -1.0
    i = 1
  } else if s.length() > 0 && s[0] == '+' {
    i = 1
  }
  while i < s.length() {
    let c = s[i]
    if c == '.' {
      in_decimal = true
      i += 1
      continue
    }
    let digit = c.to_int() - 48
    if digit >= 0 && digit <= 9 {
      if in_decimal {
        decimal_divider = decimal_divider * 10.0
        val = val + (digit.to_double() / decimal_divider)
      } else {
        val = val * 10.0 + digit.to_double()
      }
    }
    i += 1
  }
  val * sign
}

/// Tokenize the entire input into an array of tokens.
pub fn Lexer::tokenize(self : Lexer) -> Result[Array[Token], String] {
  let tokens = []
  while true {
    match self.next_token() {
      Ok(Token::Eof) => {
        tokens.push(Token::Eof)
        break
      }
      Ok(tok) => tokens.push(tok)
      Err(e) => return Err(e)
    }
  }
  Ok(tokens)
}

/// Get the next token.
pub fn Lexer::next_token(self : Lexer) -> Result[Token, String] {
  if self.pos >= self.input.length() {
    return Ok(Token::Eof)
  }

  match self.mode {
    Text => {
      // Find the next {{ or {% or {#
      let start = self.pos
      while self.pos < self.input.length() {
        let c = self.char_at(self.pos)
        if c == '{' {
          match self.peek_next() {
            Some('{') => {
              if self.pos > start {
                let text = self.input[start:self.pos]
                return Ok(Token::Text(text.to_owned()))
              }
              self.pos += 2
              self.mode = InVariable
              return Ok(Token::VariableStart)
            }
            Some('%') => {
              if self.pos > start {
                let text = self.input[start:self.pos]
                return Ok(Token::Text(text.to_owned()))
              }
              self.pos += 2
              self.mode = InBlock
              return Ok(Token::BlockStart)
            }
            Some('#') => {
              // Comment block {# ... #}
              if self.pos > start {
                let text = self.input[start:self.pos]
                return Ok(Token::Text(text.to_owned()))
              }
              self.pos += 2
              // Skip comment
              while self.pos < self.input.length() {
                if self.char_at(self.pos) == '#' && self.peek_next() == Some('}') {
                  self.pos += 2
                  break
                }
                self.pos += 1
              }
              return self.next_token() // get the next one
            }
            _ => ()
          }
        }
        self.pos += 1
      }
      // Reached EOF
      let text = self.input[start:self.pos]
      if text.length() > 0 {
        return Ok(Token::Text(text.to_owned()))
      }
      return Ok(Token::Eof)
    }
    InVariable | InBlock => {
      self.skip_whitespace()
      if self.pos >= self.input.length() {
        return Err("Unexpected EOF inside tag")
      }
      
      let c = self.char_at(self.pos)
      
      // Check for closing tags
      if self.mode == InVariable && c == '}' && self.peek_next() == Some('}') {
        self.pos += 2
        self.mode = Text
        return Ok(Token::VariableEnd)
      }
      if self.mode == InBlock && c == '%' && self.peek_next() == Some('}') {
        self.pos += 2
        self.mode = Text
        return Ok(Token::BlockEnd)
      }
      
      // Single character tokens
      match c {
        '|' => { self.pos += 1; return Ok(Token::Pipe) }
        '.' => { self.pos += 1; return Ok(Token::Dot) }
        ',' => { self.pos += 1; return Ok(Token::Comma) }
        '+' => { self.pos += 1; return Ok(Token::Plus) }
        '-' => { self.pos += 1; return Ok(Token::Minus) }
        '*' => { self.pos += 1; return Ok(Token::Mul) }
        '/' => { self.pos += 1; return Ok(Token::Div) }
        '%' => { self.pos += 1; return Ok(Token::Mod) }
        '(' => { self.pos += 1; return Ok(Token::LParen) }
        ')' => { self.pos += 1; return Ok(Token::RParen) }
        '=' => {
          if self.peek_next() == Some('=') {
            self.pos += 2
            return Ok(Token::Eq)
          } else {
            self.pos += 1
            return Ok(Token::Assign)
          }
        }
        '!' => {
          if self.peek_next() == Some('=') {
            self.pos += 2
            return Ok(Token::Neq)
          } else {
            return Err("Unexpected character '!' without '='")
          }
        }
        '>' => {
          if self.peek_next() == Some('=') {
            self.pos += 2
            return Ok(Token::Gte)
          } else {
            self.pos += 1
            return Ok(Token::Gt)
          }
        }
        '<' => {
          if self.peek_next() == Some('=') {
            self.pos += 2
            return Ok(Token::Lte)
          } else {
            self.pos += 1
            return Ok(Token::Lt)
          }
        }
        '"' => {
          self.pos += 1
          let start = self.pos
          while self.pos < self.input.length() && self.char_at(self.pos) != '"' {
            self.pos += 1
          }
          if self.pos >= self.input.length() {
            return Err("Unterminated string literal")
          }
          let text = self.input[start:self.pos]
          self.pos += 1
          return Ok(Token::StringLiteral(text.to_owned()))
        }
        _ => ()
      }

      // Numbers
      if is_digit(c) {
        let start = self.pos
        while self.pos < self.input.length() && is_digit(self.char_at(self.pos)) {
          self.pos += 1
        }
        if self.pos < self.input.length() && self.char_at(self.pos) == '.' {
          self.pos += 1
          while self.pos < self.input.length() && is_digit(self.char_at(self.pos)) {
            self.pos += 1
          }
        }
        let text = self.input[start:self.pos]
        let num = parse_double(text.to_owned())
        return Ok(Token::Number(num))
      }

      // Identifiers
      if is_ident_start(c) {
        let start = self.pos
        while self.pos < self.input.length() && is_ident_char(self.char_at(self.pos)) {
          self.pos += 1
        }
        let text = self.input[start:self.pos]
        return Ok(Token::Ident(text.to_owned()))
      }

      return Err("Unexpected character: " + c.to_string())
    }
  }
}
