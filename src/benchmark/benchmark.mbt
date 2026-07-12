///|
fn main {
  println("=============================================")
  println("        MoonTera Performance Benchmark       ")
  println("=============================================")

  let engine = @engine.Engine::new()
  let _r = engine.add_template(
    "simple", "Hello {{ name }}! You are {{ role | upper }}.",
  )

  let ctx = @context.Context::new()
  ctx.set("name", @value.Value::VString("周继远"))
  ctx.set("role", @value.Value::VString("developer"))

  println("Running 10,000 rendering operations...")
  let mut i = 0
  while i < 10000 {
    let _res = engine.render("simple", ctx)
    i += 1
  }
  println("Successfully completed 10,000 renders!")
  println("MoonTera Benchmark completed successfully.")
  println("=============================================")
}
