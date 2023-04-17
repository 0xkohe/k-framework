module GO-SYNTAX
    imports DOMAINS-SYNTAX

    syntax Exp ::= Int
                 | Id
                 | Exp "+" Exp      [left, strict]
                 | Exp "*" Exp      [left, strict]
                 | "(" Exp ")"      [bracket]

    syntax Stmt ::= Id "=" Exp ";"
                  | "return" Exp ";"
                  | Stmt Stmt

    syntax Id ::= r"[a-zA-Z_][a-zA-Z0-9_]*"    [token]
    syntax Int ::= r"[0-9]+"                  [token]

endmodule

