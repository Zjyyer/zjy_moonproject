pub struct Parser {
  tokens : Array[@lexer.Token]
  mut pos : Int
}

pub fn Parser::new(tokens : Array[@lexer.Token]) -> Parser {
  { tokens, pos: 0 }
}

fn Parser::peek(self : Parser) -> @lexer.Token {
  if self.pos < self.tokens.length() {
    self.tokens[self.pos]
  } else {
    @lexer.Token::Eof
  }
}

fn Parser::peek_next(self : Parser) -> @lexer.Token {
  if self.pos + 1 < self.tokens.length() {
    self.tokens[self.pos + 1]
  } else {
    @lexer.Token::Eof
  }
}

fn Parser::consume(self : Parser) -> @lexer.Token {
  let tok = self.peek()
  if self.pos < self.tokens.length() {
    self.pos += 1
  }
  tok
}

pub fn Parser::parse(self : Parser) -> Result[Array[Node], String] {
  self.parse_nodes()
}

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
          @lexer.Token::Ident("endif") | @lexer.Token::Ident("else") | @lexer.Token::Ident("endfor") | @lexer.Token::Ident("endblock") => {
            break
          }
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
              @lexer.Token::Ident(in_kw) => if in_kw != "in" { return Err("Expected 'in' in for loop") }
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

fn Parser::expect(self : Parser, expected : @lexer.Token) -> Result[Unit, String] {
  let tok = self.consume()
  if tok == expected {
    Ok(())
  } else {
    Err("Expected token, got something else")
  }
}

// Simple expression parser. E.g. `ident`, `"string"`, `123`, `ident | filter`, `a == b`
fn Parser::parse_expr(self : Parser) -> Result[Expr, String] {
  let mut left = match self.parse_primary() {
    Ok(e) => e
    Err(err) => return Err(err)
  }
  
  // check for binary ops
  match self.peek() {
    @lexer.Token::Eq => {
      let _ = self.consume()
      let right = match self.parse_primary() {
        Ok(e) => e
        Err(err) => return Err(err)
      }
      left = Expr::EBinaryOp("==", left, right)
    }
    @lexer.Token::Neq => {
      let _ = self.consume()
      let right = match self.parse_primary() {
        Ok(e) => e
        Err(err) => return Err(err)
      }
      left = Expr::EBinaryOp("!=", left, right)
    }
    _ => ()
  }
  
  // check for filters
  while true {
    match self.peek() {
      @lexer.Token::Pipe => {
        let _ = self.consume()
        let filter_name = match self.consume() {
          @lexer.Token::Ident(name) => name
          _ => return Err("Expected filter name after |")
        }
        // TODO: parse filter args if any. currently simplified to no args
        left = Expr::EFilter(left, filter_name, [])
      }
      _ => break
    }
  }
  
  Ok(left)
}

fn Parser::parse_primary(self : Parser) -> Result[Expr, String] {
  match self.consume() {
    @lexer.Token::Ident("true") => Ok(Expr::EBool(true))
    @lexer.Token::Ident("false") => Ok(Expr::EBool(false))
    @lexer.Token::Ident(name) => Ok(Expr::EIdent(name))
    @lexer.Token::StringLiteral(s) => Ok(Expr::EString(s))
    @lexer.Token::Number(n) => Ok(Expr::ENumber(n))
    _ => Err("Expected expression primary")
  }
}
