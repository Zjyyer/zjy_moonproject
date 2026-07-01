test "Lexer basic tokens" {
  let input = "hello {{ name }} {% if x == 1 %} yes {% endif %}"
  let lexer = Lexer::new(input)
  let tokens = lexer.tokenize().unwrap()
  assert_eq(tokens[0], Token::Text("hello "))
  assert_eq(tokens[1], Token::VariableStart)
  assert_eq(tokens[2], Token::Ident("name"))
  assert_eq(tokens[3], Token::VariableEnd)
  assert_eq(tokens[4], Token::Text(" "))
  assert_eq(tokens[5], Token::BlockStart)
  assert_eq(tokens[6], Token::Ident("if"))
  assert_eq(tokens[7], Token::Ident("x"))
  assert_eq(tokens[8], Token::Eq)
  assert_eq(tokens[9], Token::Number(1.0))
  assert_eq(tokens[10], Token::BlockEnd)
  assert_eq(tokens[11], Token::Text(" yes "))
  assert_eq(tokens[12], Token::BlockStart)
  assert_eq(tokens[13], Token::Ident("endif"))
  assert_eq(tokens[14], Token::BlockEnd)
  assert_eq(tokens[15], Token::Eof)
}

test "Lexer float numbers" {
  let input = "{{ 12.34 }} {{ 0.56 }}"
  let lexer = Lexer::new(input)
  let tokens = lexer.tokenize().unwrap()
  assert_eq(tokens[0], Token::VariableStart)
  assert_eq(tokens[1], Token::Number(12.34))
  assert_eq(tokens[2], Token::VariableEnd)
  assert_eq(tokens[3], Token::Text(" "))
  assert_eq(tokens[4], Token::VariableStart)
  assert_eq(tokens[5], Token::Number(0.56))
  assert_eq(tokens[6], Token::VariableEnd)
}

