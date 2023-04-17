module GOLANG
    imports INT
    imports BOOL
    imports ID

    syntax KResult ::= Int | Bool
    syntax Exp ::= KResult
                 | Exp "+" Exp [strict]
                 | Exp "-" Exp [strict]
                 | Exp "==" Exp [strict]
                 | "!" Exp [strict]
                 | "true"
                 | "false"
                 | Id
                 > "(" Exp ")"

    syntax Stmt ::= "var" Id "=" Exp ";"
                  | Id "=" Exp ";"
                  | Stmt Stmt
                  | "if" "(" Exp ")" Stmt
                  | "while" "(" Exp ")" Stmt
                  | "return" Exp ";"
                  | "{" Stmt "}"
                  | "func" Id "(" Ids ")" "{" Stmt "}"

    syntax Prog ::= "package" "main" ";" Stmt "func" "main" "(" ")" "{" Stmt "}"

    syntax Ids ::= List{Id, ","}
    syntax Id ::= r"[a-zA-Z_][a-zA-Z0-9_]*" [token]

    configuration <T>
                    <k> $PGM:Prog </k>
                    <state> .Map </state>
                  </T>

    // Evaluation rules for expressions
    rule <k> I1:Int + I2:Int => I1 +Int I2 ...</k>
    rule <k> I1:Int - I2:Int => I1 -Int I2 ...</k>
    rule <k> I1:Int == I2:Int => I1 ==Int I2 ...</k>
    rule <k> !true => false ...</k>
    rule <k> !false => true ...</k>

    // Variable declaration and assignment
    rule <k> var X:Id = E:Exp ; => . ...</k>
         <state> STATE => STATE [ X <- E ] </state>

    rule <k> X:Id => I ...</k>
         <state>... X |-> I ...</state>

    rule <k> X:Id = E:Exp ; => . ...</k>
         <state> STATE => STATE [ X <- E ] </state>

    // Control structures
    rule <k> if (true) S1:Stmt => S1 ...</k>
    rule <k> if (false) S1:Stmt => . ...</k>
    rule <k> while (E:Exp) S:Stmt => if (E) { S while (E) S; } ...</k>

    // Function definition and call
    rule <k> func F:Id (ARGS:Ids) { S:Stmt } => . ...</k>
         <state> STATE => STATE [ F <- klabel(F) ] </state>
         <function> .Map => .Map [ klabel(F) <- (ARGS, S) ] </function>

    rule <k> F:Id ; => R:KResult ...</k>
         <function>... klabel(F) |-> (ARGS:Ids, S:Stmt) ...</function>
         <k> R:KResult => . ...</k>
         <state>... F |-> _:KResult ...</state>
         <env> ENV </env>
         rule <k> F:Id ; => call F(ARGS:Ids); ...</k>
         <function>... klabel(F) |-> (ARGS:Ids, _:Stmt) ...</function>
         <state>... F |-> klabel(F) ...</state>

    rule <k> call F:Id(Es:Exps); => . ...</k>
         <k> ARGS:Ids => Es ...</k>
         <env> ENV => ENV </env>
         <function>... klabel(F) |-> (ARGS:Ids, S:Stmt) ...</function>
         <state> STATE => STATE </state>
    
    syntax Exps ::= List{Exp, ","}
    
    rule <k> return E:Exp ; => E ...</k>
    
    // Additional rules for blocks and sequencing
    rule <k> { S:Stmt } => S ...</k>
    rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ...</k>

endmodule


