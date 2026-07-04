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

test "Evaluator filters" {
  let ctx = @context.Context::new()
  ctx.set("name", @value.Value::VString("MoonBit"))
  ctx.set("empty_str", @value.Value::VString(""))
  ctx.set("nil_val", @value.Value::VNull)
  
  let eval = Evaluator::new(ctx)
  
  // Test upper: name | upper
  let expr_upper = @parser.Expr::EFilter(@parser.Expr::EIdent("name"), "upper", [])
  assert_eq(eval.eval_expr(expr_upper).unwrap(), @value.Value::VString("MOONBIT"))
  
  // Test lower: name | lower
  let expr_lower = @parser.Expr::EFilter(@parser.Expr::EIdent("name"), "lower", [])
  assert_eq(eval.eval_expr(expr_lower).unwrap(), @value.Value::VString("moonbit"))
  
  // Test length: name | length
  let expr_len = @parser.Expr::EFilter(@parser.Expr::EIdent("name"), "length", [])
  assert_eq(eval.eval_expr(expr_len).unwrap(), @value.Value::VNumber(7.0))
  
  // Test default on null: nil_val | default("fallback")
  let expr_def1 = @parser.Expr::EFilter(
    @parser.Expr::EIdent("nil_val"),
    "default",
    [@parser.Expr::EString("fallback")]
  )
  assert_eq(eval.eval_expr(expr_def1).unwrap(), @value.Value::VString("fallback"))

  // Test default on empty string: empty_str | default("fallback")
  let expr_def2 = @parser.Expr::EFilter(
    @parser.Expr::EIdent("empty_str"),
    "default",
    [@parser.Expr::EString("fallback")]
  )
  assert_eq(eval.eval_expr(expr_def2).unwrap(), @value.Value::VString("fallback"))
}

test "Evaluator property access" {
  let ctx = @context.Context::new()
  let user_map : Map[String, @value.Value] = Map([])
  user_map.set("name", @value.Value::VString("周继远"))
  user_map.set("age", @value.Value::VNumber(20.0))
  ctx.set("user", @value.Value::VObject(user_map))
  
  let eval = Evaluator::new(ctx)
  
  // user.name
  let expr_name = @parser.Expr::EGet(@parser.Expr::EIdent("user"), "name")
  assert_eq(eval.eval_expr(expr_name).unwrap(), @value.Value::VString("周继远"))
  
  // user.age
  let expr_age = @parser.Expr::EGet(@parser.Expr::EIdent("user"), "age")
  assert_eq(eval.eval_expr(expr_age).unwrap(), @value.Value::VNumber(20.0))
}

test "Evaluator loop helpers" {
  let ctx = @context.Context::new()
  ctx.set("items", @value.Value::VArray([
    @value.Value::VString("A"),
    @value.Value::VString("B")
  ]))
  
  let eval = Evaluator::new(ctx)
  
  // {% for item in items %}{{ loop.index }}:{{ item }} {% endfor %}
  let nodes = [
    @parser.Node::For(
      "item",
      @parser.Expr::EIdent("items"),
      [
        @parser.Node::Print(@parser.Expr::EGet(@parser.Expr::EIdent("loop"), "index")),
        @parser.Node::Text(":"),
        @parser.Node::Print(@parser.Expr::EIdent("item")),
        @parser.Node::Text(" ")
      ]
    )
  ]
  
  let result = eval.render(nodes).unwrap()
  assert_eq(result, "1:A 2:B ")
}

test "Evaluator join & contains filters" {
  let ctx = @context.Context::new()
  ctx.set("words", @value.Value::VArray([
    @value.Value::VString("apple"),
    @value.Value::VString("banana"),
    @value.Value::VString("cherry")
  ]))
  ctx.set("phrase", @value.Value::VString("hello moonbit template"))
  
  let eval = Evaluator::new(ctx)
  
  // words | join(", ")
  let expr_join = @parser.Expr::EFilter(
    @parser.Expr::EIdent("words"),
    "join",
    [@parser.Expr::EString(", ")]
  )
  assert_eq(eval.eval_expr(expr_join).unwrap(), @value.Value::VString("apple, banana, cherry"))
  
  // phrase | contains("moonbit")
  let expr_contains_str = @parser.Expr::EFilter(
    @parser.Expr::EIdent("phrase"),
    "contains",
    [@parser.Expr::EString("moonbit")]
  )
  assert_eq(eval.eval_expr(expr_contains_str).unwrap(), @value.Value::VBool(true))
  
  // words | contains("banana")
  let expr_contains_arr = @parser.Expr::EFilter(
    @parser.Expr::EIdent("words"),
    "contains",
    [@parser.Expr::EString("banana")]
  )
  assert_eq(eval.eval_expr(expr_contains_arr).unwrap(), @value.Value::VBool(true))
}

