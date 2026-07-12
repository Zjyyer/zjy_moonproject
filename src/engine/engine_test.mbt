///|
test "Engine basic" {
  let engine = Engine::new()
  engine
  .add_template(
    "index.html", "<html><body><h1>Hello {{ user }}</h1></body></html>",
  )
  .unwrap()

  let ctx = @context.Context::new()
  ctx.set("user", @value.Value::VString("MoonBit User"))

  let result = engine.render("index.html", ctx).unwrap()
  assert_eq(result, "<html><body><h1>Hello MoonBit User</h1></body></html>")
}

///|
test "Engine inheritance" {
  let engine = Engine::new()
  engine
  .add_template("base.html", "[ {% block content %}default{% endblock %} ]")
  .unwrap()
  engine
  .add_template(
    "child.html", "{% extends \"base.html\" %}{% block content %}hello {{ name }}{% endblock %}",
  )
  .unwrap()

  let ctx = @context.Context::new()
  ctx.set("name", @value.Value::VString("MoonBit"))

  let result = engine.render("child.html", ctx).unwrap()
  assert_eq(result, "[ hello MoonBit ]")
}
