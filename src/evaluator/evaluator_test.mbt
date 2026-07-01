test "Evaluator basic" {
  let ctx = @context.Context::new()
  ctx.set("name", @value.Value::VString("MoonBit"))
  ctx.set("is_admin", @value.Value::VBool(true))
  
  let eval = Evaluator::new(ctx)
  
  let nodes = [
    @parser.Node::Text("Hello, "),
    @parser.Node::Print(@parser.Expr::EIdent("name")),
    @parser.Node::Text("! "),
    @parser.Node::If(
      @parser.Expr::EIdent("is_admin"),
      [@parser.Node::Text("Welcome Admin.")],
      [@parser.Node::Text("Welcome User.")]
    )
  ]
  
  let result = eval.render(nodes).unwrap()
  assert_eq(result, "Hello, MoonBit! Welcome Admin.")
}

test "Evaluator operators" {
  let ctx = @context.Context::new()
  ctx.set("name", @value.Value::VString("MoonBit"))
  ctx.set("is_admin", @value.Value::VBool(true))
  ctx.set("is_blocked", @value.Value::VBool(false))
  ctx.set("x", @value.Value::VNumber(5.0))
  
  let eval = Evaluator::new(ctx)
  
  // Test arithmetic: (x + 3) * 2 - 4
  let expr_arith = @parser.Expr::EBinaryOp(
    "-",
    @parser.Expr::EBinaryOp(
      "*",
      @parser.Expr::EBinaryOp("+", @parser.Expr::EIdent("x"), @parser.Expr::ENumber(3.0)),
      @parser.Expr::ENumber(2.0)
    ),
    @parser.Expr::ENumber(4.0)
  )
  
  let val_arith = eval.eval_expr(expr_arith).unwrap()
  assert_eq(val_arith, @value.Value::VNumber(12.0)) // (5 + 3) * 2 - 4 = 12
  
  // Test logical and comparisons: is_admin and not is_blocked
  let expr_logical = @parser.Expr::EBinaryOp(
    "and",
    @parser.Expr::EIdent("is_admin"),
    @parser.Expr::EUnaryOp("not", @parser.Expr::EIdent("is_blocked"))
  )
  
  let val_logical = eval.eval_expr(expr_logical).unwrap()
  assert_eq(val_logical, @value.Value::VBool(true))
  
  // Test string concat fallback: name + " User"
  let expr_concat = @parser.Expr::EBinaryOp(
    "+",
    @parser.Expr::EIdent("name"),
    @parser.Expr::EString(" User")
  )
  let val_concat = eval.eval_expr(expr_concat).unwrap()
  assert_eq(val_concat, @value.Value::VString("MoonBit User"))
}

test "Evaluator for loop" {
  let ctx = @context.Context::new()
  ctx.set(
    "items",
    @value.Value::VArray([
      @value.Value::VString("Apple"),
      @value.Value::VString("Banana"),
      @value.Value::VString("Cherry")
    ])
  )
  
  let eval = Evaluator::new(ctx)
  
  // {% for fruit in items %}- {{ fruit }} {% endfor %}
  let nodes = [
    @parser.Node::For(
      "fruit",
      @parser.Expr::EIdent("items"),
      [
        @parser.Node::Text("- "),
        @parser.Node::Print(@parser.Expr::EIdent("fruit")),
        @parser.Node::Text(" ")
      ]
    )
  ]
  
  let result = eval.render(nodes).unwrap()
  assert_eq(result, "- Apple - Banana - Cherry ")
}
