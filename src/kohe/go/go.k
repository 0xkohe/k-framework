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
  // for 3+3 instead 3 + 3
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
  syntax SimpleStmt ::= Assignment | ShortVarDecl | IncDecStmt
  syntax Assignment ::= Id "=" Exp [strict(2)]
  syntax ShortVarDecl ::= Id ":=" Exp [strict(2)]
  syntax IncDecStmt ::= Id "++" | Id "--"


  // Statements (now include SimpleStmt)
  syntax Statement ::= SimpleStmt | Print | Block | IfStmt | ForStmt  | BreakStmt | ContinueStmt
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
  

  // --- For with ForClause only ---
  syntax ForStmt ::= "for" ForClause Block
  
  syntax BreakStmt ::= "break"
  syntax ContinueStmt ::= "continue"
/*
  ForStmt   = "for" [ Condition | ForClause | RangeClause ] Block .
Condition = Expression .
*/
  
  // Enumerate optional pieces (Init; Cond; Post)
  syntax ForClause ::= SimpleStmt ";" Exp ";" SimpleStmt
  | SimpleStmt ";" ";" SimpleStmt
  | SimpleStmt ";" Exp ";"
  | ";" Exp ";" SimpleStmt
  | ";" ";" SimpleStmt
  | ";" Exp ";"
  | SimpleStmt ";" ";"
  | ";" ";"

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
  
  

  rule <k> X:Id ++ => X = (X + 1) ... </k>
     <tenv> ... X |-> int ... </tenv>

  rule <k> X:Id -- => X = (X - 1) ... </k>
     <tenv> ... X |-> int ... </tenv>



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
  
  // --- ForClause desugaring to an internal loop ---
  syntax KItem ::= loop(Exp, K, Block)
  syntax KItem ::= loopV(Exp, Exp, K, Block) [strict(1)]
  syntax KItem ::= "breakSignal" | "continueSignal"

  rule <k> continue => continueSignal ... </k>
  // loop に当たるまで、手前の KItem をどんどん捨てる
  rule <k> continueSignal ~> _KI:KItem => continueSignal ... </k> [owise]
  // loop に当たったら post を実行してループ継続
  rule <k> continueSignal ~> loop(E, SP, B) => SP ~> loop(E, SP, B) ... </k>

  rule <k> break    => breakSignal    ... </k>
  rule <k> breakSignal ~> _KI:KItem => breakSignal ... </k> [owise]
  rule <k> breakSignal ~> loop(_E, _SP, _B) => .K ... </k>

  
  // For の各形を loop に落とす（ここはそのままでOK）
  rule <k> for S1:SimpleStmt ; E:Exp ; S2:SimpleStmt B:Block => S1 ~> loop(E, S2, B) ... </k>
  rule <k> for S1:SimpleStmt ; ; S2:SimpleStmt B:Block       => S1 ~> loop(true, S2, B) ... </k>
  rule <k> for S1:SimpleStmt ; E:Exp ; B:Block               => S1 ~> loop(E, .K, B)   ... </k>
  rule <k> for ; E:Exp ; S2:SimpleStmt B:Block               =>       loop(E, S2, B)   ... </k>
  rule <k> for ; ; S2:SimpleStmt B:Block                     =>       loop(true, S2, B) ... </k>
  rule <k> for ; E:Exp ; B:Block                             =>       loop(E, .K, B)    ... </k>
  rule <k> for S1:SimpleStmt ; ; B:Block                     => S1 ~> loop(true, .K, B) ... </k>
  rule <k> for ; ; B:Block                                   =>       loop(true, .K, B)  ... </k>
  
  // loop の評価（毎回 E を評価して分岐する）
  rule <k> loop(E:Exp, SP:K, B:Block) => loopV(E, E, SP, B) ... </k>
  
  // 条件が true のとき：本体→post→再帰
  rule <k> loopV(true, E, SP:K, B:Block) => B ~> SP ~> loop(E, SP, B) ... </k>
  
  // 条件が false のとき：終了
  rule <k> loopV(false, _E, _SP, _B) => .K ... </k>


  // K result predicate
  syntax Bool ::= isKResult(K) [symbol(isKResult), function]
  rule isKResult(_:Int)  => true
  rule isKResult(_:Bool) => true
  rule isKResult(_)      => false [owise]
endmodule
