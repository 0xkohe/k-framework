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
  
requires "domains.md"

module GO-SYNTAX
  // imports INT-SYNTAX
  imports UNSIGNED-INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // Program / blocks
  syntax Program ::= "package" "main" "func" "main" "(" ")" Block
  syntax Block   ::= "{" StatementList ";" "}"
  syntax StatementList ::= List{Statement, ";"}

  // Types (int / bool only)
  syntax Type ::= "int" | "bool"

  // --- SimpleStmt (subset) ---
  syntax SimpleStmt ::= Assignment | ShortVarDecl
  syntax Assignment ::= Id "=" Exp [strict(2)]
  syntax ShortVarDecl ::= Id ":=" Exp [strict(2)]

  // Statements (now include SimpleStmt)
  syntax Statement ::= SimpleStmt | Print | Block | IfStmt
                     | "var" Id Type "=" Exp  [strict(3)]   // Declaration stays as Statement (not SimpleStmt)

  // print (Int only for now)
  syntax Print ::= "print" "(" Exp ")" [strict]

  // Unified Exp (int/bool)
  syntax Exp ::= Int | Bool | Id | "(" Exp ")" [bracket]
               > "!" Exp [seqstrict]
               | "-" Exp [seqstrict]
               > left:
                 Exp "*" Exp [left, seqstrict]
               | Exp "/" Exp [left, seqstrict]
               | Exp "%" Exp [left, seqstrict]
               > left:
                 Exp "+" Exp [left, seqstrict]
               | Exp "-" Exp [left, seqstrict]
               > non-assoc:
                 Exp "<"  Exp [seqstrict]
               | Exp ">"  Exp [seqstrict]
               | Exp "==" Exp [seqstrict]
               > left:
                 Exp "&&" Exp [left, seqstrict]
               | Exp "||" Exp [left, seqstrict]

  // If with optional init (SimpleStmt) — Go-style (no parentheses)
  syntax IfStmt ::= "if" Exp Block                                   [strict(1)]
                  | "if" Exp Block "else" Block                       [strict(1)]
                  | "if" Exp Block "else" IfStmt                      [strict(1)]
                  | "if" SimpleStmt ";" Exp Block                      // desugared by rule
                  | "if" SimpleStmt ";" Exp Block "else" Block        // desugared by rule
                  | "if" SimpleStmt ";" Exp Block "else" IfStmt       // desugared by rule

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

  // print —— Int only
  rule <k> print(I:Int) => .K ... </k>
       <out> OL => OL ListItem(I) </out>

  // --- typed var decl / short var decl / assignment ---
  // var X int = I
  rule <k> var X:Id int = I:Int => .K ... </k>
       <tenv> R => R [ X <- int ] </tenv>
       <envI> Rho => Rho [ X <- I ] </envI>

  // var X bool = B
  rule <k> var X:Id bool = B:Bool => .K ... </k>
       <tenv> R => R [ X <- bool ] </tenv>
       <envB> Rho => Rho [ X <- B ] </envB>

  // short var decl: X := <exp>
  rule <k> X:Id := I:Int => .K ... </k>
       <tenv> R => R [ X <- int ] </tenv>
       <envI> Rho => Rho [ X <- I ] </envI>

  rule <k> X:Id := B:Bool => .K ... </k>
       <tenv> R => R [ X <- bool ] </tenv>
       <envB> Rho => Rho [ X <- B ] </envB>

  // assignment guarded by type env
  rule <k> X:Id = I:Int => .K ... </k>
       <tenv> ... X |-> int ... </tenv>
       <envI> Rho => Rho [ X <- I ] </envI>

  rule <k> X:Id = B:Bool => .K ... </k>
       <tenv> ... X |-> bool ... </tenv>
       <envB> Rho => Rho [ X <- B ] </envB>

  // lookups
  rule <k> X:Id => I ... </k>
       <envI> ... X |-> I:Int ... </envI>
  rule <k> X:Id => B ... </k>
       <envB> ... X |-> B:Bool ... </envB>

  // arithmetic
  rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
  rule <k> I1:Int - I2:Int => I1 -Int I2 ... </k>
  rule <k> I1:Int * I2:Int => I1 *Int I2 ... </k>
  rule <k> I1:Int / I2:Int => I1 /Int I2 ... </k>
  rule <k> I1:Int % I2:Int => I1 %Int I2 ... </k>

  // comparisons / boolean ops
  rule <k> I1:Int <  I2:Int => I1 <Int  I2 ... </k>
  rule <k> I1:Int >  I2:Int => I1 >Int  I2 ... </k>
  rule <k> I1:Int == I2:Int => I1 ==Int I2 ... </k>
  rule <k> - I:Int => 0 -Int I ... </k>


  rule <k> B1:Bool && B2:Bool => B1 andBool B2 ... </k>
  rule <k> B1:Bool || B2:Bool => B1 orBool  B2 ... </k>
  rule <k> ! B:Bool           => notBool B    ... </k>

  // --- If desugaring when init present ---
  rule <k> if S:SimpleStmt ; E:Exp B:Block => S ~> if E B ... </k>
  rule <k> if S:SimpleStmt ; E:Exp B1:Block else B2:Block => S ~> if E B1 else B2 ... </k>
  rule <k> if S:SimpleStmt ; E:Exp B1:Block else I2:IfStmt => S ~> if E B1 else I2 ... </k>

  // --- If semantics (no parens) ---
  rule <k> if true  B:Block => B  ... </k>
  rule <k> if false _B:Block => .K ... </k>
  rule <k> if true  B1:Block else _B2:Block => B1 ... </k>
  rule <k> if false _B1:Block else B2:Block => B2 ... </k>


  // K result predicate
  syntax Bool ::= isKResult(K) [symbol(isKResult), function]
  rule isKResult(_:Int)  => true
  rule isKResult(_:Bool) => true
  rule isKResult(_)      => false [owise]
endmodule

// ---
// Quick tests
// 1) init あり
// package main func main(){
//   if x := 3+4; x > 5 { print(x); } else { print(0); };
// }
// => <out>: ListItem(7)
//
// 2) 代入を init に
// package main func main(){
//   var a int = 0;
//   if a = 10; a == 10 { print(a); };
// }
// => <out>: ListItem(10)
