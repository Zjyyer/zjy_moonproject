// Built-in Filters Usage Example

fn run_filters_demo() {
  let engine = @engine.Engine::new()
  
  // Register template
  let template = "Name: {{ user | upper }} | Lower: {{ user | lower }} | Fallback: {{ nil_val | default(\"Guest\") }}"
  let _ = engine.add_template("profile", template)
  
  // Bind context variables
  let ctx = @context.Context::new()
  ctx.set("user", @value.Value::VString("moOnBiT"))
  ctx.set("nil_val", @value.Value::VNull)
  
  // Render
  match engine.render("profile", ctx) {
    Ok(rendered) => println("Output: " + rendered)
    Err(err) => println("Error: " + err)
  }
}
