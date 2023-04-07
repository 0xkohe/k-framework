module LESSON-06-C-SYNTAX
  imports BOOL-SYNTAX

  syntax Bool ::= "(" Bool ")" [bracket]
                > "!" Bool [function]
                > left:
                  Bool "&&" Bool [function]
                | Bool "^" Bool [function]
                | Bool "||" Bool [function]
endmodule

module LESSON-06-C
  imports LESSON-06-C-SYNTAX
  imports BOOL

  rule ! AIUEO => notBool AIUEO
  rule A && AIUEO => A andBool AIUEO
  rule A ^ AIUEO => A xorBool AIUEO
  rule A || AIUEO => A orBool AIUEO
endmodule
