pub struct Engine {
  templates : Map[String, Array[@parser.Node]]
}

pub fn Engine::new() -> Engine {
  { templates: Map::of([]) }
}

pub fn Engine::add_template(self : Engine, name : String, source : String) -> Result[Unit, String] {
  let lexer = @lexer.Lexer::new(source)
  let tokens = match lexer.tokenize() {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let parser = @parser.Parser::new(tokens)
  let ast = match parser.parse() {
    Ok(a) => a
    Err(e) => return Err(e)
  }
  self.templates.set(name, ast)
  Ok(())
}

pub fn Engine::render(self : Engine, name : String, ctx : @context.Context) -> Result[String, String] {
  match self.templates.get(name) {
    Some(ast) => {
      let eval = @evaluator.Evaluator::new(ctx)
      eval.render(ast)
    }
    None => Err("Template not found: " + name)
  }
}
