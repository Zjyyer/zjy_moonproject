pub struct Engine {
  templates : Map[String, Array[@parser.Node]]
}

pub fn Engine::new() -> Engine {
  { templates: Map([]) }
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

fn collect_blocks(nodes : Array[@parser.Node], blocks : Map[String, Array[@parser.Node]]) -> Unit {
  for node in nodes {
    match node {
      @parser.Node::Block(name, body) => {
        blocks.set(name, body)
        collect_blocks(body, blocks)
      }
      @parser.Node::If(_, then_body, else_body) => {
        collect_blocks(then_body, blocks)
        collect_blocks(else_body, blocks)
      }
      @parser.Node::For(_, _, body) => {
        collect_blocks(body, blocks)
      }
      _ => ()
    }
  }
}

fn replace_blocks(nodes : Array[@parser.Node], blocks : Map[String, Array[@parser.Node]]) -> Array[@parser.Node] {
  let result = []
  for node in nodes {
    match node {
      @parser.Node::Block(name, body) => {
        let new_body = match blocks.get(name) {
          Some(child_body) => replace_blocks(child_body, blocks)
          None => replace_blocks(body, blocks)
        }
        result.push(@parser.Node::Block(name, new_body))
      }
      @parser.Node::If(cond, then_body, else_body) => {
        let new_then = replace_blocks(then_body, blocks)
        let new_else = replace_blocks(else_body, blocks)
        result.push(@parser.Node::If(cond, new_then, new_else))
      }
      @parser.Node::For(item, expr, body) => {
        let new_body = replace_blocks(body, blocks)
        result.push(@parser.Node::For(item, expr, new_body))
      }
      _ => result.push(node)
    }
  }
  result
}

fn find_extends(nodes : Array[@parser.Node]) -> Option[String] {
  for node in nodes {
    match node {
      @parser.Node::Extends(name) => return Some(name)
      _ => ()
    }
  }
  None
}

fn Engine::resolve_inheritance(self : Engine, nodes : Array[@parser.Node]) -> Result[Array[@parser.Node], String] {
  match find_extends(nodes) {
    Some(parent_name) => {
      let parent_nodes = match self.templates.get(parent_name) {
        Some(ast) => ast
        None => return Err("Parent template not found: " + parent_name)
      }
      let child_blocks = Map([])
      collect_blocks(nodes, child_blocks)
      let merged_nodes = replace_blocks(parent_nodes, child_blocks)
      self.resolve_inheritance(merged_nodes)
    }
    None => Ok(nodes)
  }
}

pub fn Engine::render(self : Engine, name : String, ctx : @context.Context) -> Result[String, String] {
  match self.templates.get(name) {
    Some(ast) => {
      let resolved_ast = match self.resolve_inheritance(ast) {
        Ok(a) => a
        Err(e) => return Err(e)
      }
      let eval = @evaluator.Evaluator::new(ctx)
      eval.render(resolved_ast)
    }
    None => Err("Template not found: " + name)
  }
}
