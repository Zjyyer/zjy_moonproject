fn main {
  println("=============================================")
  println("       MoonTera Template Engine Demo         ")
  println("=============================================")
  
  let engine = @engine.Engine::new()
  
  // 1. Add base and child templates for inheritance demo
  let base_html = "<html>" +
    "<head><title>{% block title %}Default Title{% endblock %}</title></head>" +
    "<body>" +
    "  <div class=\"header\">" +
    "    <h1>Welcome to MoonTera</h1>" +
    "  </div>" +
    "  <div class=\"content\">" +
    "    {% block content %}{% endblock %}" +
    "  </div>" +
    "</body>" +
    "</html>"
  
  let child_html = "{% extends \"base.html\" %}" +
    "{% block title %}My Custom Page{% endblock %}" +
    "{% block content %}" +
    "  <h2>Fruits List</h2>" +
    "  <ul>" +
    "    {% for item in fruits %}" +
    "      <li>{{ item | upper }}</li>" +
    "    {% endfor %}" +
    "  </ul>" +
    "  <p>Admin Status: {% if is_admin %}ACTIVE{% else %}INACTIVE{% endif %}</p>" +
    "  <p>Expression Test (5 * 3 + 2): {{ (5 * 3) + 2 }}</p>" +
    "  <p>Null Fallback: {{ nil_val | default(\"Guest User\") }}</p>" +
    "{% endblock %}"

  let _r1 = engine.add_template("base.html", base_html)
  let _r2 = engine.add_template("child.html", child_html)
  
  // 2. Set up context variables
  let ctx = @context.Context::new()
  ctx.set("is_admin", @value.Value::VBool(true))
  ctx.set("nil_val", @value.Value::VNull)
  ctx.set("fruits", @value.Value::VArray([
    @value.Value::VString("apple"),
    @value.Value::VString("banana"),
    @value.Value::VString("cherry")
  ]))
  
  // 3. Render
  match engine.render("child.html", ctx) {
    Ok(result) => {
      println("Rendered Output:")
      println(result)
    }
    Err(e) => {
      println("Render Error: " + e)
    }
  }
  println("=============================================")
}
