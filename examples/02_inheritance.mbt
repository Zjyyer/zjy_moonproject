// Template Inheritance Example

fn run_inheritance_demo() {
  let engine = @engine.Engine::new()
  
  // Register base parent template
  let base_tpl = "Layout Start | {% block main %}Default Main{% endblock %} | Layout End"
  let _ = engine.add_template("base.html", base_tpl)
  
  // Register child template that extends base
  let child_tpl = "{% extends \"base.html\" %}{% block main %}Child Main Content ({{ user }}){% endblock %}"
  let _ = engine.add_template("child.html", child_tpl)
  
  // Bind context variables
  let ctx = @context.Context::new()
  ctx.set("user", @value.Value::VString("Zjyyer"))
  
  // Render
  match engine.render("child.html", ctx) {
    Ok(rendered) => println("Output: " + rendered)
    Err(err) => println("Error: " + err)
  }
}
