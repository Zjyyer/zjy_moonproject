test "Parser basic" {
  let input = "hello {{ name }} {% if true %} yes {% endif %}"
  let lexer = @lexer.Lexer::new(input)
  let tokens = lexer.tokenize().unwrap()
  
  let parser = Parser::new(tokens)
  let ast = parser.parse().unwrap()
  
  assert_eq(ast.length(), 4)
  assert_eq(ast[0], Node::Text("hello "))
  assert_eq(ast[1], Node::Print(Expr::EIdent("name")))
  assert_eq(ast[2], Node::Text(" "))
  
  match ast[3] {
    Node::If(cond, then_body, else_body) => {
      assert_eq(cond, Expr::EBool(true))
      assert_eq(then_body.length(), 1)
      assert_eq(then_body[0], Node::Text(" yes "))
      assert_eq(else_body.length(), 0)
    }
    _ => fail!("Expected If node")
  }
}
