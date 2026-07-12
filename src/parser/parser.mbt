///|
pub struct Parser {
  tokens : Array[@lexer.Token]
  mut pos : Int
}

///|
pub fn Parser::new(tokens : Array[@lexer.Token]) -> Parser {
  { tokens, pos: 0 }
}

///|
fn Parser::peek(self : Parser) -> @lexer.Token {
  if self.pos < self.tokens.length() {
    self.tokens[self.pos]
  } else {
    @lexer.Token::Eof
  }
}

///|
fn Parser::peek_next(self : Parser) -> @lexer.Token {
  if self.pos + 1 < self.tokens.length() {
    self.tokens[self.pos + 1]
  } else {
    @lexer.Token::Eof
  }
}

///|
fn Parser::consume(self : Parser) -> @lexer.Token {
  let tok = self.peek()
  if self.pos < self.tokens.length() {
    self.pos += 1
  }
  tok
}

///|
pub fn Parser::parse(self : Parser) -> Result[Array[Node], String] {
  self.parse_nodes()
}

///|
fn Parser::parse_nodes(self : Parser) -> Result[Array[Node], String] {
  let nodes = []
  while true {
    match self.peek() {
      @lexer.Token::Eof => break
      @lexer.Token::Text(text) => {
        let _ = self.consume()
        nodes.push(Node::Text(text))
      }
      @lexer.Token::VariableStart => {
        let _ = self.consume()
        let expr = match self.parse_expr() {
          Ok(e) => e
          Err(err) => return Err(err)
        }
        match self.consume() {
          @lexer.Token::VariableEnd => nodes.push(Node::Print(expr))
          _ => return Err("Expected '}}' to close variable")
        }
      }
      @lexer.Token::BlockStart => {
        match self.peek_next() {
          @lexer.Token::Ident("endif")
          | @lexer.Token::Ident("else")
          | @lexer.Token::Ident("endfor")
          | @lexer.Token::Ident("endblock") => break
          _ => ()
        }

        let _ = self.consume() // Consume {%
        match self.consume() {
          @lexer.Token::Ident("if") => {
            let condition = match self.parse_expr() {
              Ok(c) => c
              Err(err) => return Err(err)
            }
            match self.expect(@lexer.Token::BlockEnd) {
              Ok(_) => ()
              Err(err) => return Err(err)
            }
            let then_body = match self.parse_nodes() {
              Ok(b) => b
              Err(err) => return Err(err)
            }

            let mut else_body = []
            match self.peek_next() {
              @lexer.Token::Ident("else") => {
                let _ = self.consume() // {%
                let _ = self.consume() // else
                match self.expect(@lexer.Token::BlockEnd) {
                  Ok(_) => ()
                  Err(err) => return Err(err)
                }
                else_body = match self.parse_nodes() {
                  Ok(b) => b
                  Err(err) => return Err(err)
                }
              }
              _ => ()
            }

            let _ = self.consume() // {%
            match self.consume() {
              @lexer.Token::Ident("endif") => {
                match self.expect(@lexer.Token::BlockEnd) {
                  Ok(_) => ()
                  Err(err) => return Err(err)
                }
                nodes.push(Node::If(condition, then_body, else_body))
              }
              _ => return Err("Expected 'endif'")
            }
          }
          @lexer.Token::Ident("for") => {
            let item_name = match self.consume() {
              @lexer.Token::Ident(name) => name
              _ => return Err("Expected identifier in for loop")
            }
            match self.consume() {
              @lexer.Token::Ident(in_kw) =>
                if in_kw != "in" {
                  return Err("Expected 'in' in for loop")
                }
              _ => return Err("Expected 'in' in for loop")
            }
            let list_expr = match self.parse_expr() {
              Ok(e) => e
              Err(err) => return Err(err)
            }
            match self.expect(@lexer.Token::BlockEnd) {
              Ok(_) => ()
              Err(err) => return Err(err)
            }
            let body = match self.parse_nodes() {
              Ok(b) => b
              Err(err) => return Err(err)
            }

            let _ = self.consume() // {%
            match self.consume() {
              @lexer.Token::Ident("endfor") => {
                match self.expect(@lexer.Token::BlockEnd) {
                  Ok(_) => ()
                  Err(err) => return Err(err)
                }
                nodes.push(Node::For(item_name, list_expr, body))
              }
              _ => return Err("Expected 'endfor'")
            }
          }
          @lexer.Token::Ident("block") => {
            let block_name = match self.consume() {
              @lexer.Token::Ident(name) => name
              _ => return Err("Expected block name")
            }
            match self.expect(@lexer.Token::BlockEnd) {
              Ok(_) => ()
              Err(err) => return Err(err)
            }
            let body = match self.parse_nodes() {
              Ok(b) => b
              Err(err) => return Err(err)
            }

            let _ = self.consume() // {%
            match self.consume() {
              @lexer.Token::Ident("endblock") => {
                match self.expect(@lexer.Token::BlockEnd) {
                  Ok(_) => ()
                  Err(err) => return Err(err)
                }
                nodes.push(Node::Block(block_name, body))
              }
              _ => return Err("Expected 'endblock'")
            }
          }
          @lexer.Token::Ident("extends") => {
            let tpl_name = match self.consume() {
              @lexer.Token::StringLiteral(name) => name
              _ => return Err("Expected string literal for extends")
            }
            match self.expect(@lexer.Token::BlockEnd) {
              Ok(_) => ()
              Err(err) => return Err(err)
            }
            nodes.push(Node::Extends(tpl_name))
          }
          _ => return Err("Unknown block tag")
        }
      }
      _ => return Err("Unexpected token in template body")
    }
  }
  Ok(nodes)
}

///|
fn Parser::expect(
  self : Parser,
  expected : @lexer.Token,
) -> Result[Unit, String] {
  let tok = self.consume()
  if tok == expected {
    Ok(())
  } else {
    Err("Expected token, got something else")
  }
}

// Simple expression parser. E.g. `ident`, `"string"`, `123`, `ident | filter`, `a == b`

///|
fn Parser::parse_expr(self : Parser) -> Result[Expr, String] {
  self.parse_or()
}

///|
fn Parser::parse_or(self : Parser) -> Result[Expr, String] {
  let mut left = match self.parse_and() {
    Ok(e) => e
    Err(err) => return Err(err)
  }
  while true {
    match self.peek() {
      @lexer.Token::Ident("or") => {
        let _ = self.consume()
        let right = match self.parse_and() {
          Ok(e) => e
          Err(err) => return Err(err)
        }
        left = Expr::EBinaryOp("or", left, right)
      }
      _ => break
    }
  }
  Ok(left)
}

///|
fn Parser::parse_and(self : Parser) -> Result[Expr, String] {
  let mut left = match self.parse_not() {
    Ok(e) => e
    Err(err) => return Err(err)
  }
  while true {
    match self.peek() {
      @lexer.Token::Ident("and") => {
        let _ = self.consume()
        let right = match self.parse_not() {
          Ok(e) => e
          Err(err) => return Err(err)
        }
        left = Expr::EBinaryOp("and", left, right)
      }
      _ => break
    }
  }
  Ok(left)
}

///|
fn Parser::parse_not(self : Parser) -> Result[Expr, String] {
  match self.peek() {
    @lexer.Token::Ident("not") => {
      let _ = self.consume()
      let expr = match self.parse_not() {
        Ok(e) => e
        Err(err) => return Err(err)
      }
      Ok(Expr::EUnaryOp("not", expr))
    }
    _ => self.parse_comparison()
  }
}

///|
fn Parser::parse_comparison(self : Parser) -> Result[Expr, String] {
  let mut left = match self.parse_additive() {
    Ok(e) => e
    Err(err) => return Err(err)
  }
  while true {
    match self.peek() {
      @lexer.Token::Eq
      | @lexer.Token::Neq
      | @lexer.Token::Lt
      | @lexer.Token::Lte
      | @lexer.Token::Gt
      | @lexer.Token::Gte => {
        let op = match self.consume() {
          @lexer.Token::Eq => "=="
          @lexer.Token::Neq => "!="
          @lexer.Token::Lt => "<"
          @lexer.Token::Lte => "<="
          @lexer.Token::Gt => ">"
          @lexer.Token::Gte => ">="
          _ => ""
        }
        let right = match self.parse_additive() {
          Ok(e) => e
          Err(err) => return Err(err)
        }
        left = Expr::EBinaryOp(op, left, right)
      }
      _ => break
    }
  }
  Ok(left)
}

///|
fn Parser::parse_additive(self : Parser) -> Result[Expr, String] {
  let mut left = match self.parse_multiplicative() {
    Ok(e) => e
    Err(err) => return Err(err)
  }
  while true {
    match self.peek() {
      @lexer.Token::Plus | @lexer.Token::Minus => {
        let op = match self.consume() {
          @lexer.Token::Plus => "+"
          @lexer.Token::Minus => "-"
          _ => ""
        }
        let right = match self.parse_multiplicative() {
          Ok(e) => e
          Err(err) => return Err(err)
        }
        left = Expr::EBinaryOp(op, left, right)
      }
      _ => break
    }
  }
  Ok(left)
}

///|
fn Parser::parse_multiplicative(self : Parser) -> Result[Expr, String] {
  let mut left = match self.parse_unary() {
    Ok(e) => e
    Err(err) => return Err(err)
  }
  while true {
    match self.peek() {
      @lexer.Token::Mul | @lexer.Token::Div | @lexer.Token::Mod => {
        let op = match self.consume() {
          @lexer.Token::Mul => "*"
          @lexer.Token::Div => "/"
          @lexer.Token::Mod => "%"
          _ => ""
        }
        let right = match self.parse_unary() {
          Ok(e) => e
          Err(err) => return Err(err)
        }
        left = Expr::EBinaryOp(op, left, right)
      }
      _ => break
    }
  }
  Ok(left)
}

///|
fn Parser::parse_unary(self : Parser) -> Result[Expr, String] {
  match self.peek() {
    @lexer.Token::Minus => {
      let _ = self.consume()
      let expr = match self.parse_unary() {
        Ok(e) => e
        Err(err) => return Err(err)
      }
      Ok(Expr::EUnaryOp("-", expr))
    }
    @lexer.Token::Plus => {
      let _ = self.consume()
      self.parse_unary()
    }
    _ => self.parse_filtered()
  }
}

///|
fn Parser::parse_member(self : Parser) -> Result[Expr, String] {
  let mut expr = match self.parse_primary() {
    Ok(e) => e
    Err(err) => return Err(err)
  }
  while true {
    match self.peek() {
      @lexer.Token::Dot => {
        let _ = self.consume()
        match self.consume() {
          @lexer.Token::Ident(field) => expr = Expr::EGet(expr, field)
          _ => return Err("Expected identifier after '.'")
        }
      }
      _ => break
    }
  }
  Ok(expr)
}

///|
fn Parser::parse_filtered(self : Parser) -> Result[Expr, String] {
  let mut left = match self.parse_member() {
    Ok(e) => e
    Err(err) => return Err(err)
  }
  while true {
    match self.peek() {
      @lexer.Token::Pipe => {
        let _ = self.consume()
        let filter_name = match self.consume() {
          @lexer.Token::Ident(name) => name
          _ => return Err("Expected filter name after |")
        }
        let args = []
        if self.peek() == @lexer.Token::LParen {
          let _ = self.consume()
          if self.peek() != @lexer.Token::RParen {
            while true {
              let arg = match self.parse_expr() {
                Ok(e) => e
                Err(err) => return Err(err)
              }
              args.push(arg)
              match self.peek() {
                @lexer.Token::Comma => {
                  let _ = self.consume()
                }
                @lexer.Token::RParen => break
                _ => return Err("Expected ',' or ')' in filter arguments")
              }
            }
          }
          match self.consume() {
            @lexer.Token::RParen => ()
            _ => return Err("Expected ')' to close filter arguments")
          }
        }
        left = Expr::EFilter(left, filter_name, args)
      }
      _ => break
    }
  }
  Ok(left)
}

///|
fn Parser::parse_primary(self : Parser) -> Result[Expr, String] {
  match self.consume() {
    @lexer.Token::Ident("true") => Ok(Expr::EBool(true))
    @lexer.Token::Ident("false") => Ok(Expr::EBool(false))
    @lexer.Token::Ident(name) => Ok(Expr::EIdent(name))
    @lexer.Token::StringLiteral(s) => Ok(Expr::EString(s))
    @lexer.Token::Number(n) => Ok(Expr::ENumber(n))
    @lexer.Token::LParen => {
      let expr = match self.parse_expr() {
        Ok(e) => e
        Err(err) => return Err(err)
      }
      match self.consume() {
        @lexer.Token::RParen => Ok(expr)
        _ => Err("Expected ')' to close group")
      }
    }
    _ => Err("Expected expression primary")
  }
}
