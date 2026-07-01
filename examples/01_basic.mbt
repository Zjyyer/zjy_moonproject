// Basic Variable Interpolation and Conditions Example
// To run this within your project, import `@engine`, `@context`, `@value`

fn run_basic_demo() {
  let engine = @engine.Engine::new()
  
  // Register template
  let template = "Hello {{ username }}! You have {{ points + 10 }} points. {% if vip %}Welcome VIP!{% endif %}"
  let _ = engine.add_template("welcome", template)
  
  // Bind context variables
  let ctx = @context.Context::new()
  ctx.set("username", @value.Value::VString("Alice"))
  ctx.set("points", @value.Value::VNumber(90.0))
  ctx.set("vip", @value.Value::VBool(true))
  
  // Render output
  match engine.render("welcome", ctx) {
    Ok(rendered) => println("Output: " + rendered)
    Err(err) => println("Error: " + err)
  }
}
