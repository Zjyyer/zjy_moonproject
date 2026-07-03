/// AST Expressions used inside tags like {{ ... }} and {% if ... %}
pub(all) enum Expr {
  EString(String)
  ENumber(Double)
  EBool(Bool)
  EIdent(String)
  EFilter(Expr, String, Array[Expr]) // expr | filter_name(args...)
  EUnaryOp(String, Expr) // e.g. not x, -y
  EBinaryOp(String, Expr, Expr) // e.g. a == b
  EGet(Expr, String) // expr.field
} derive(Eq, Show, Debug)

/// AST Nodes representing the template structure
pub(all) enum Node {
  Text(String)
  Print(Expr) // {{ expr }}
  If(Expr, Array[Node], Array[Node]) // {% if expr %} body {% else %} else_body {% endif %}
  For(String, Expr, Array[Node]) // {% for item in list_expr %} body {% endfor %}
  Block(String, Array[Node]) // {% block name %} body {% endblock %}
  Extends(String) // {% extends "name" %}
} derive(Eq, Show, Debug)
