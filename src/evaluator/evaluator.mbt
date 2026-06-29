pub struct Evaluator {
  ctx : @context.Context
}

pub fn Evaluator::new(ctx : @context.Context) -> Evaluator {
  { ctx, }
}

pub fn Evaluator::render(self : Evaluator, nodes : Array[@parser.Node]) -> Result[String, String] {
  let mut output = ""
  for node in nodes {
    let s = match self.render_node(node) {
      Ok(s) => s
      Err(e) => return Err(e)
    }
    output = output + s
  }
  Ok(output)
}

fn Evaluator::render_node(self : Evaluator, node : @parser.Node) -> Result[String, String] {
  match node {
    @parser.Node::Text(text) => Ok(text)
    @parser.Node::Print(expr) => {
      let val = match self.eval_expr(expr) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      Ok(self.format_value(val))
    }
    @parser.Node::If(cond, then_body, else_body) => {
      let cond_val = match self.eval_expr(cond) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      if cond_val.is_truthy() {
        self.render(then_body)
      } else {
        self.render(else_body)
      }
    }
    _ => Err("Unsupported node (For/Block/Extends not fully implemented yet)")
  }
}

fn Evaluator::eval_expr(self : Evaluator, expr : @parser.Expr) -> Result[@value.Value, String] {
  match expr {
    @parser.Expr::EBool(b) => Ok(@value.Value::VBool(b))
    @parser.Expr::ENumber(n) => Ok(@value.Value::VNumber(n))
    @parser.Expr::EString(s) => Ok(@value.Value::VString(s))
    @parser.Expr::EIdent(name) => {
      match self.ctx.get(name) {
        Some(v) => Ok(v)
        None => Ok(@value.Value::VNull) // Or error
      }
    }
    @parser.Expr::EBinaryOp(op, left, right) => {
      let l = match self.eval_expr(left) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      let r = match self.eval_expr(right) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      if op == "==" {
        Ok(@value.Value::VBool(l == r))
      } else if op == "!=" {
        Ok(@value.Value::VBool(l != r))
      } else {
        Err("Unsupported operator")
      }
    }
    _ => Err("Unsupported expr in evaluator")
  }
}

fn Evaluator::format_value(_self : Evaluator, v : @value.Value) -> String {
  match v {
    @value.Value::VNull => ""
    @value.Value::VBool(true) => "true"
    @value.Value::VBool(false) => "false"
    @value.Value::VNumber(n) => n.to_string()
    @value.Value::VString(s) => s
    _ => "<object>"
  }
}
