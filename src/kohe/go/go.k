module GO-SYNTAX
    imports INT-SYNTAX
    imports BOOL-SYNTAX

    syntax Id ::= r"[a-zA-Z_][a-zA-Z0-9_]*" [token]

    // ---------- EXPRESSIONS ----------
    syntax Exp ::= Int | Bool | Id
                 | Exp "+" Exp  [left]
                 | Exp "-" Exp  [left]
                 | Exp "*" Exp  [left]
                 | Exp "/" Exp  [left]
                 | Exp "<" Exp  [left]
                 | Exp "==" Exp [left]
                 | "(" Exp ")"                  [bracket]

    // ---------- STATEMENTS ----------
    syntax Stmt ::= "{ " Stmts " }"          
                  | "var" Id "=" Exp           // VarDecl
                  | Id "=" Exp                 // Assign
                  | "if" "(" Exp ")" Stmt     // If without else
                  | "if" "(" Exp ")" Stmt "else" Stmt // If with else
                  | "for" Stmt                  // infinite loop style: for { .. }
                  | Id "(" ")"                // simple call – zero‑arg function
                  // | Stmt ";" Stmt              [right]
    syntax Stmts ::= List{Stmt,";"}

    // ---------- PROGRAM ----------
    syntax Program ::= Stmts
endmodule

module GO
    imports GO-SYNTAX
    imports INT
    imports BOOL
    imports MAP // for environments
    imports LIST

    // ---------- CONFIG ----------
    configuration <k> $PGM:Program </k>
                  <env> .Map </env>
                  <out> .List </out>

    // ---------- HELPER ----------
    syntax Val ::= Int | Bool

    syntax Exp ::= Val
    rule <k> I:Int => I ... </k>
    rule <k> B:Bool => B ... </k>

    // look‑up
    rule <k> X:Id => V ... </k>
         <env> ... X |-> V ... </env>

    // ------------ EXP EVAL -------------
    rule <k> (I1:Int + I2:Int) => I1 +Int I2 ... </k>
    rule <k> (I1:Int - I2:Int) => I1 -Int I2 ... </k>
    rule <k> (I1:Int * I2:Int) => I1 *Int I2 ... </k>
    rule <k> (I1:Int / I2:Int) => I1 /Int I2 ... </k>
    rule <k> (I1:Int <  I2:Int) => (I1 <Int I2) ... </k>
    rule <k> (I1:Int == I2:Int) => (I1 ==Int I2) ... </k>

    // ---------- STATEMENTS ----------
    syntax KResult ::= ".stmt"

    // sequencing
    rule <k> (S1:Stmt ; S2:Stmt) => S1 ~> S2 ... </k>

    // blocks
    rule <k> { SS:Stmts } => SS ... </k>
    rule <k> .List => .stmt ... </k>

    // var decl
    rule <k> var X:Id = V:Val => .stmt ... </k>
         <env> Rho => Rho [ X <- V ] </env>

    // assignment (assuming already declared)
    rule <k> X:Id = V:Val => .stmt ... </k>
         <env> Rho ( X |-> _ ) => Rho [ X <- V ] </env>

    // if without else – true
    rule <k> if (true)  S:Stmt => S ... </k>
    // if without else – false
    rule <k> if (false) S:Stmt => .stmt ... </k>

    // if with else true
    rule <k> if (true)  S1:Stmt else S2:Stmt => S1 ... </k>
    // false
    rule <k> if (false) S1:Stmt else S2:Stmt => S2 ... </k>

    // for { body }   – execute body then loop again
    rule <k> for B:Stmt => { B ; for B } ... </k>

    // simple zero-arg function call – currently only builtin print()
    // rule <k> print() => .stmt ... </k>
    //      <out> O => ListItem("printed") O </out>

    // program is list of stmts – execute sequentially
    rule <k> SS:Stmts => SS ... </k>
endmodule
