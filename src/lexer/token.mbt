/// Token represents the lexical tokens in a template.
pub(all) enum Token {
  Text(String)
  VariableStart // {{
  VariableEnd // }}
  BlockStart // {%
  BlockEnd // %}
  Ident(String)
  StringLiteral(String)
  Number(Double)
  Pipe // |
  Dot // .
  Comma // ,
  Eq // ==
  Neq // !=
  Gt // >
  Lt // <
  Gte // >=
  Lte // <=
  Assign // =
  Plus // +
  Minus // -
  Mul // *
  Div // /
  Mod // %
  LParen // (
  RParen // )
  Eof
} derive(Eq, Debug)

pub impl Show for Token with output(self, logger) {
  self.output(logger)
}
