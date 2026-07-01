# MoonTera: Full-Featured Template Parser & Rendering Engine for MoonBit

[![MoonBit](https://img.shields.io/badge/Language-MoonBit-black?style=flat-square)](https://www.moonbitlang.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

**MoonTera** is a robust, dynamic, and extensible template engine written from scratch in native MoonBit. Inspired by Python's **Jinja2** and Rust's **Tera**, MoonTera parses text templates into an Abstract Syntax Tree (AST) at runtime and dynamically evaluates them against a context environment. 

It is designed for server-side HTML rendering, configuration file generation (YAML/JSON/TOML), email templates, and code generator scripts.

---

## 🌟 Core Features

- **Lexer & Parser (AST)**: A robust tokenizer and a recursive-descent expression parser with mathematical and comparative operator precedence.
- **Variable Interpolation**: Seamless variable access `{{ user.name }}` with support for dynamic types.
- **Expressions & Operators**: Supports arithmetic operations (`+`, `-`, `*`, `/`, `%`), comparison operators (`==`, `!=`, `<`, `<=`, `>`, `>=`), and logical short-circuiting (`and`, `or`, `not`).
- **Template Scoping**: Stack-based parent-child scoping (`new_child`) for local loop variables.
- **Control Flow**: Conditionals (`{% if %}` / `{% else %}`) and loop iterations (`{% for item in items %}`).
- **Template Inheritance**: True inheritance with `{% extends "base.html" %}` and overridden block placeholders `{% block main %} ... {% endblock %}`.
- **Built-in Filters**: Support pipe-syntax filters `{{ name | upper }}` with arguments:
  - `upper`: Convert text to uppercase.
  - `lower`: Convert text to lowercase.
  - `length`: Get array or string length.
  - `default(value)`: Apply fallback value if string is empty or null.

---

## 🏗️ Architecture Design

MoonTera is built on a modular pipeline ensuring clear separation of concerns:

```
Template String ──► [ Lexer ] ──► Token Stream ──► [ Parser ] ──► AST (Node/Expr)
                                                                     │
Context Data ────► [ Environment Scopes ] ───────────────────────────┼──► [ Evaluator ] ──► Rendered Output
```

- **`src/value/value.mbt`**: Dynamic data representation supporting Null, Boolean, Number, String, Array, and Object.
- **`src/lexer/lexer.mbt`**: Custom lexical scanner including decimal/float tokenization.
- **`src/parser/parser.mbt`**: Syntactic parser resolving block tags and operators.
- **`src/context/context.mbt`**: Scoping layer resolving variable bindings.
- **`src/evaluator/evaluator.mbt`**: Traverses nodes and expressions to format text.
- **`src/filters/filters.mbt`**: Text formatting and mapping functions.
- **`src/engine/engine.mbt`**: Main API and Template Inheritance block merger.

---

## 🚀 Quick Start

### 1. Basic Template Evaluation

```moonbit
fn main {
  let engine = @engine.Engine::new()
  
  // Register template
  let template = "Hello {{ username }}! You have {{ points + 10 }} points."
  let _ = engine.add_template("welcome", template)
  
  // Bind context variables
  let ctx = @context.Context::new()
  ctx.set("username", @value.Value::VString("Alice"))
  ctx.set("points", @value.Value::VNumber(90.0))
  
  // Render output
  match engine.render("welcome", ctx) {
    Ok(rendered) => println(rendered) // Prints: Hello Alice! You have 100 points.
    Err(err) => println("Error: " + err)
  }
}
```

### 2. Template Inheritance (Extends & Block)

```moonbit
// base.html
// "[ {% block content %}default{% endblock %} ]"

// child.html
// "{% extends \"base.html\" %}{% block content %}hello {{ name }}{% endblock %}"

fn run_inheritance() {
  let engine = @engine.Engine::new()
  let _ = engine.add_template("base.html", "[ {% block content %}default{% endblock %} ]")
  let _ = engine.add_template("child.html", "{% extends \"base.html\" %}{% block content %}hello {{ name }}{% endblock %}")
  
  let ctx = @context.Context::new()
  ctx.set("name", @value.Value::VString("MoonBit"))
  
  let result = engine.render("child.html", ctx).unwrap()
  println(result) // Prints: [ hello MoonBit ]
}
```

---

## 🛠️ Running the Built-in Demo

MoonTera comes with a preconfigured command line entrypoint showing all features working together. You can run it locally with:

```bash
moon run src/main
```

## 📂 Project Structure

```
.
├── LICENSE
├── README.md
├── moon.mod.json
├── examples/                   # Standalone code examples
│   ├── README.md
│   ├── 01_basic.mbt
│   ├── 02_inheritance.mbt
│   └── 03_custom_filters.mbt
└── src/                        # Library source code
    ├── context/                # Nested variable context mapping
    ├── engine/                 # Top level template manager
    ├── evaluator/              # AST evaluator & expression executor
    ├── filters/                # Standard pipe filters
    ├── lexer/                  # Tokenizer and double parser
    ├── main/                   # Runnable CLI demo application
    ├── parser/                 # Precedence parser and AST node structures
    └── value/                  # Dynamic Value types
```

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
