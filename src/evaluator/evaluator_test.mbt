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
