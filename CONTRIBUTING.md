# Contributing to MoonTera

Thank you for your interest in contributing to MoonTera! This document provides guidelines for setting up your local environment and submitting contributions.

## Development Setup

1. **Install MoonBit Toolchain**:
   Follow instructions at [moonbitlang.com](https://www.moonbitlang.com/) to install the compiler and build tools.
   
2. **Clone the Repository**:
   ```bash
   git clone https://github.com/Zjyyer/zjy_moonproject.git
   cd zjy_moonproject
   ```

## Development Commands

- **Build all packages**:
  ```bash
  moon build
  ```

- **Run unit and integration tests**:
  ```bash
  moon test
  ```

- **Run the CLI demonstration**:
  ```bash
  moon run src/main
  ```

## Project Directory Layout

- `src/lexer`: Tokenizer parsing strings into tag-based token streams.
- `src/parser`: Syntactic parser converting token streams into ASTs.
- `src/context`: Map-based stack resolving variable scope.
- `src/evaluator`: Node/Expression traversal and text composition engine.
- `src/engine`: Main engine manager coordinating file reading and block merges.

## Coding Guidelines

- Keep all functions documented.
- Write unit tests for any new parser expressions or filters in their respective `*_test.mbt` files.
- Run `moon test` before proposing changes to ensure all checks pass without warnings.
