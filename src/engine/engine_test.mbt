test "Engine basic" {
  let engine = Engine::new()
  engine.add_template("index.html", "<html><body><h1>Hello {{ user }}</h1></body></html>").unwrap()
  
  let ctx = @context.Context::new()
  ctx.set("user", @value.Value::VString("MoonBit User"))
  
  let result = engine.render("index.html", ctx).unwrap()
  assert_eq(result, "<html><body><h1>Hello MoonBit User</h1></body></html>")
}
