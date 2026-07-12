///|
pub struct Evaluator {
  ctx : @context.Context
}

///|
pub fn Evaluator::new(ctx : @context.Context) -> Evaluator {
  { ctx, }
}

///|
pub fn Evaluator::render(
  self : Evaluator,
  nodes : Array[@parser.Node],
) -> Result[String, String] {
  self.render_with_ctx(nodes, self.ctx)
}

///|
fn Evaluator::render_with_ctx(
  self : Evaluator,
  nodes : Array[@parser.Node],
  ctx : @context.Context,
) -> Result[String, String] {
  let mut output = ""
  for node in nodes {
    let s = match self.render_node(node, ctx) {
      Ok(s) => s
      Err(e) => return Err(e)
    }
    output = output + s
  }
  Ok(output)
}

///|
fn Evaluator::render_node(
  self : Evaluator,
  node : @parser.Node,
  ctx : @context.Context,
) -> Result[String, String] {
  match node {
    @parser.Node::Text(text) => Ok(text)
    @parser.Node::Print(expr) => {
      let val = match self.eval_expr_with_ctx(expr, ctx) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      Ok(self.format_value(val))
    }
    @parser.Node::If(cond, then_body, else_body) => {
      let cond_val = match self.eval_expr_with_ctx(cond, ctx) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      if cond_val.is_truthy() {
        self.render_with_ctx(then_body, ctx)
      } else {
        self.render_with_ctx(else_body, ctx)
      }
    }
    @parser.Node::For(item_name, list_expr, body) => {
      let val = match self.eval_expr_with_ctx(list_expr, ctx) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      match val {
        @value.Value::VArray(arr) => {
          let mut res = ""
          let len = arr.length()
          let mut idx = 0
          while idx < len {
            let elem = arr[idx]
            let child_ctx = @context.Context::new_child(ctx)
            child_ctx.set(item_name, elem)

            let loop_map : Map[String, @value.Value] = Map([])
            loop_map.set("index0", @value.Value::VNumber(idx.to_double()))
            loop_map.set("index", @value.Value::VNumber((idx + 1).to_double()))
            loop_map.set("first", @value.Value::VBool(idx == 0))
            loop_map.set("last", @value.Value::VBool(idx == len - 1))
            loop_map.set("length", @value.Value::VNumber(len.to_double()))
            child_ctx.set("loop", @value.Value::VObject(loop_map))

            let rendered = match self.render_with_ctx(body, child_ctx) {
              Ok(s) => s
              Err(e) => return Err(e)
            }
            res = res + rendered
            idx = idx + 1
          }
          Ok(res)
        }
        _ => Err("For loop expects an array")
      }
    }
    @parser.Node::Block(_name, body) => self.render_with_ctx(body, ctx)
    @parser.Node::Extends(_) => Ok("")
  }
}

///|
pub fn Evaluator::eval_expr(
  self : Evaluator,
  expr : @parser.Expr,
) -> Result[@value.Value, String] {
  self.eval_expr_with_ctx(expr, self.ctx)
}

///|
fn Evaluator::eval_expr_with_ctx(
  self : Evaluator,
  expr : @parser.Expr,
  ctx : @context.Context,
) -> Result[@value.Value, String] {
  match expr {
    @parser.Expr::EBool(b) => Ok(@value.Value::VBool(b))
    @parser.Expr::ENumber(n) => Ok(@value.Value::VNumber(n))
    @parser.Expr::EString(s) => Ok(@value.Value::VString(s))
    @parser.Expr::EIdent(name) =>
      match ctx.get(name) {
        Some(v) => Ok(v)
        None => Ok(@value.Value::VNull)
      }
    @parser.Expr::EGet(inner, field) => {
      let val = match self.eval_expr_with_ctx(inner, ctx) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      match val {
        @value.Value::VObject(obj) =>
          match obj.get(field) {
            Some(v) => Ok(v)
            None => Ok(@value.Value::VNull)
          }
        _ => Ok(@value.Value::VNull)
      }
    }
    @parser.Expr::EUnaryOp(op, inner) => {
      let val = match self.eval_expr_with_ctx(inner, ctx) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      if op == "not" {
        Ok(@value.Value::VBool(!val.is_truthy()))
      } else if op == "-" {
        match val {
          @value.Value::VNumber(n) => Ok(@value.Value::VNumber(-n))
          _ => Err("Unary minus expects a number")
        }
      } else {
        Err("Unsupported unary operator: " + op)
      }
    }
    @parser.Expr::EBinaryOp(op, left, right) => {
      let l = match self.eval_expr_with_ctx(left, ctx) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      if op == "and" {
        if l.is_truthy() {
          self.eval_expr_with_ctx(right, ctx)
        } else {
          Ok(l)
        }
      } else if op == "or" {
        if l.is_truthy() {
          Ok(l)
        } else {
          self.eval_expr_with_ctx(right, ctx)
        }
      } else {
        let r = match self.eval_expr_with_ctx(right, ctx) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        if op == "==" {
          Ok(@value.Value::VBool(l == r))
        } else if op == "!=" {
          Ok(@value.Value::VBool(l != r))
        } else {
          match (l, r) {
            (@value.Value::VNumber(n1), @value.Value::VNumber(n2)) =>
              if op == "+" {
                Ok(@value.Value::VNumber(n1 + n2))
              } else if op == "-" {
                Ok(@value.Value::VNumber(n1 - n2))
              } else if op == "*" {
                Ok(@value.Value::VNumber(n1 * n2))
              } else if op == "/" {
                Ok(@value.Value::VNumber(n1 / n2))
              } else if op == "%" {
                Ok(@value.Value::VNumber(n1 % n2))
              } else if op == "<" {
                Ok(@value.Value::VBool(n1 < n2))
              } else if op == "<=" {
                Ok(@value.Value::VBool(n1 <= n2))
              } else if op == ">" {
                Ok(@value.Value::VBool(n1 > n2))
              } else if op == ">=" {
                Ok(@value.Value::VBool(n1 >= n2))
              } else {
                Err("Unsupported operator on numbers: " + op)
              }
            (@value.Value::VString(s1), @value.Value::VString(s2)) =>
              if op == "+" {
                Ok(@value.Value::VString(s1 + s2))
              } else if op == "<" {
                Ok(@value.Value::VBool(s1 < s2))
              } else if op == "<=" {
                Ok(@value.Value::VBool(s1 <= s2))
              } else if op == ">" {
                Ok(@value.Value::VBool(s1 > s2))
              } else if op == ">=" {
                Ok(@value.Value::VBool(s1 >= s2))
              } else {
                Err("Unsupported operator on strings: " + op)
              }
            _ =>
              if op == "+" {
                Ok(
                  @value.Value::VString(
                    self.format_value(l) + self.format_value(r),
                  ),
                )
              } else {
                Err("Type mismatch or unsupported operator: " + op)
              }
          }
        }
      }
    }
    @parser.Expr::EFilter(inner, filter_name, args_exprs) => {
      let val = match self.eval_expr_with_ctx(inner, ctx) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      let args = []
      for arg_expr in args_exprs {
        let arg_val = match self.eval_expr_with_ctx(arg_expr, ctx) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        args.push(arg_val)
      }
      @filters.apply_filter(filter_name, val, args)
    }
  }
}

///|
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
