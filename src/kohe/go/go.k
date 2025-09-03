requires "domains.md"


module GO-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX  

  /*
Semicolons¶
The formal syntax uses semicolons ";" as terminators in a number of productions. Go programs may omit most of these semicolons using the following two rules:

When the input is broken into tokens, a semicolon is automatically inserted into the token stream immediately after a line's final token if that token is
an identifier
an integer, floating-point, imaginary, rune, or string literal
one of the keywords break, continue, fallthrough, or return
one of the operators and punctuation ++, --, ), ], or }
To allow complex statements to occupy a single line, a semicolon may be omitted before a closing ")" or "}".
To reflect idiomatic use, code examples in this document elide semicolons using these rules.
  */

  // Program / blocks (same as before)
  syntax Program ::= "package" "main" "func" "main" "(" ")" Block
  syntax Block   ::= "{" StatementList ";" "}"
  syntax StatementList ::= List{Statement, ";"}

  // Types (Goのうち int / bool のみ)
  syntax Type ::= "int" | "bool"

  // Statements
  syntax Statement ::= Print | Block | IfStmt
                     | "var" Id Type "=" Exp           [strict(3)] // typed declaration
                     | Id "=" Exp                      [strict(2)]  // assignment

  // print: まずは Int のみ（必要なら Bool も追加予定）
  syntax Print ::= "print" "(" Exp ")" [strict]

  // --- Unified Exp (int と bool の両方を含む表現) ---
  syntax Exp ::= Int | Bool | Id 
               | "(" Exp ")" [bracket]
               // unary
               > "!" Exp [seqstrict]   // expects Bool; yields Bool
               // multiplicative
               > left:
                 Exp "*" Exp [left, seqstrict]
               | Exp "/" Exp [left, seqstrict]
               | Exp "%" Exp [left, seqstrict]
               // additive
               > left:
                 Exp "+" Exp [left, seqstrict]
               | Exp "-" Exp [left, seqstrict]
               // comparisons (non-assoc)
               > non-assoc:
                 Exp "<"  Exp [seqstrict]
               | Exp ">"  Exp [seqstrict]
               | Exp "==" Exp [seqstrict]
               // logical
               > left:
                 Exp "&&" Exp [left, seqstrict]
               | Exp "||" Exp [left, seqstrict]

  // If (条件は Exp だが意味規則で Bool に評価される想定)
  syntax IfStmt ::= "if" "(" Exp ")" Block              [strict(1)]
                  | "if" "(" Exp ")" Block "else" Block [strict(1)]
endmodule


module GO
  imports GO-SYNTAX
  imports INT
  imports LIST
  imports BOOL
  imports MAP
  imports ID

  configuration
    <T>
      <k> $PGM:Program </k>
      <out> .List </out>
      <tenv> .Map </tenv>  // Id ↦ Type  (int|bool)
      <envI> .Map </envI>  // Id ↦ Int
      <envB> .Map </envB>  // Id ↦ Bool
    </T>

  // Entry
  rule <k> package main func main ( ) B:Block => B ... </k>

  // Block sequencing
  syntax K ::= toSeq(StatementList) [function]
  rule toSeq(.StatementList) => .K
  rule toSeq(S:Statement ; SL:StatementList) => S ~> toSeq(SL)
  rule <k> { SL:StatementList ; } => toSeq(SL) ... </k>

  // print —— Int only for now
  rule <k> print(I:Int) => .K ... </k>
       <out> OL => OL ListItem(I) </out>

  // --- typed var decl / assign ---
  // var X int = <Exp:Int>
  rule <k> var X:Id int = I:Int => .K ... </k>
       <tenv> R => R [ X <- int ] </tenv>
       <envI> Rho => Rho [ X <- I ] </envI>

  // var X bool = <Exp:Bool>
  rule <k> var X:Id bool = B:Bool => .K ... </k>
       <tenv> R => R [ X <- bool ] </tenv>
       <envB> Rho => Rho [ X <- B ] </envB>

  // assignment guarded by type env
  rule <k> X:Id = I:Int => .K ... </k>
       <tenv> ... X |-> int ... </tenv>
       <envI> Rho => Rho [ X <- I ] </envI>

  rule <k> X:Id = B:Bool => .K ... </k>
       <tenv> ... X |-> bool ... </tenv>
       <envB> Rho => Rho [ X <- B ] </envB>

  // --- lookup (context-sensitive) ---
  rule <k> X:Id => I ... </k>
       <envI> ... X |-> I:Int ... </envI>
  rule <k> X:Id => B ... </k>
       <envB> ... X |-> B:Bool ... </envB>

  // --- arithmetic over Int (Int -> Int) ---
  rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
  rule <k> I1:Int - I2:Int => I1 -Int I2 ... </k>
  rule <k> I1:Int * I2:Int => I1 *Int I2 ... </k>
  rule <k> I1:Int / I2:Int => I1 /Int I2 ... </k>
  rule <k> I1:Int % I2:Int => I1 %Int I2 ... </k>

  // --- comparisons (Int × Int -> Bool) ---
  rule <k> I1:Int <  I2:Int => I1 <Int  I2 ... </k>
  rule <k> I1:Int >  I2:Int => I1 >Int  I2 ... </k>
  rule <k> I1:Int == I2:Int => I1 ==Int I2 ... </k>

  // --- logical (Bool × Bool -> Bool), unary !
  rule <k> B1:Bool && B2:Bool => B1 andBool B2 ... </k>
  rule <k> B1:Bool || B2:Bool => B1 orBool  B2 ... </k>
  rule <k> ! B:Bool           => notBool B    ... </k>

  // --- if semantics (条件は Bool に評価された後に適用) ---
  rule <k> if ( true  ) B:Block => B  ... </k>
  rule <k> if ( false ) _B:Block => .K ... </k>

  rule <k> if ( true  ) B1:Block else _B2:Block => B1 ... </k>
  rule <k> if ( false ) _B1:Block else B2:Block => B2 ... </k>

  // K result predicate (unchanged)
  syntax Bool ::= isKResult(K) [symbol(isKResult), function]
  rule isKResult(_:Int)  => true
  rule isKResult(_:Bool) => true
  rule isKResult(_)      => false [owise]
endmodule
