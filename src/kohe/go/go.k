requires "domains.md"


module GO-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

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
  
  syntax Program ::= "package" "main" "func" "main" "(" ")" Block
  syntax Block ::= "{" StatementList ";" "}"
  syntax StatementList ::= List{Statement, ";"}
  syntax Statement ::= Print | Block | IfStmt

  syntax Print ::= "print" "(" Exp ")" [strict]
  
  
  syntax Exp ::= Int
  | "(" Exp ")" [bracket]
  > left:
    Exp "*" Exp [left, seqstrict]
  | Exp "/" Exp [left, seqstrict]
  | Exp "%" Exp [left, seqstrict]
  > left:
    Exp "+" Exp [left, seqstrict]
  | Exp "-" Exp [left, seqstrict]
  


  syntax BExp ::= Bool
| "(" BExp ")" [bracket]
| Exp "<" Exp [seqstrict]
| Exp ">" Exp [seqstrict]
| Exp "==" Exp [seqstrict]
| "!" BExp [seqstrict]
> BExp "&&" BExp [left, seqstrict]
> BExp "||" BExp [left, seqstrict]


// If statements (with and without else)
syntax IfStmt ::= "if" "(" BExp ")" Block  [strict(1)] //[macro]
// syntax Stmt ::= "if" "(" Exp ")" Block [macro] => rule if (E) B => if (E) B else {}
                | "if" "(" BExp ")" Block "else" Block [strict(1)]

endmodule


module GO
imports GO-SYNTAX
imports INT
imports LIST
imports BOOL


 configuration
 <T>
 <k> $PGM:Program </k>
 <out> .List </out>
 </T>
 
 
 // エントリ（ヘッダを剥がして main の Block を実行）
 rule <k> package main func main ( ) B:Block => B ... </k>

 syntax K ::= toSeq(StatementList) [function]
 rule toSeq(.StatementList) => .K
 rule toSeq(S:Statement ; SL:StatementList) => S ~> toSeq(SL)
 rule <k> { SL:StatementList ; } => toSeq(SL) ... </k>
 
// print: 評価済みの Int を <out> に追加
 rule <k> print(I :Int) => .K ... </k>
 <out> OL => OL ListItem(I) </out>
// 算術
 rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
 rule <k> I1:Int - I2:Int => I1 -Int I2 ... </k>
 rule <k> I1:Int * I2:Int => I1 *Int I2 ... </k>
 rule <k> I1:Int / I2:Int => I1 /Int I2 ... </k>
 rule <k> I1:Int % I2:Int => I1 %Int I2 ... </k>
 

 // boolean operators / comparisons
rule <k> I1:Int < I2:Int => I1 <Int I2 ... </k>
rule <k> I1:Int > I2:Int => I1 >Int I2 ... </k>
rule <k> I1:Int == I2:Int => I1 ==Int I2 ... </k>

rule <k> B1:Bool && B2:Bool => B1 andBool B2 ... </k>
rule <k> B1:Bool || B2:Bool => B1 orBool B2 ... </k>
rule <k> ! B:Bool => notBool B ... </k>


// for macro
// rule if (E) S => if (E) S else {}

// if semantics
rule <k> if ( true ) B:Block => B ... </k>
rule <k> if ( false ) _B:Block => .K ... </k>


rule <k> if ( true ) B1:Block else _:Block => B1 ... </k>
rule <k> if ( false ) _:Block else B2:Block => B2 ... </k>

 syntax Bool ::= isKResult(K) [symbol(isKResult), function]
 rule isKResult(_:Int) => true
 rule isKResult(_:Bool) => true
 rule isKResult(_) => false [owise]

endmodule
