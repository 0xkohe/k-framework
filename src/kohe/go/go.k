requires "domains.md"


module GO-SYNTAX
  imports INT-SYNTAX
  
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
  syntax Block ::= "{" StmtList ";" "}"
  syntax StmtList ::= List{Stmt, ";"}
  syntax Stmt ::= Print | Block

  syntax Print ::= "print" "(" Exp ")" [strict]
  
  
  syntax Exp ::= Int
  | "(" Exp ")" [bracket]
  > Exp "*" Exp [left, seqstrict]
  > Exp "+" Exp [left, seqstrict]
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
 
 syntax K ::= toSeq(StmtList) [function]
 rule toSeq(.StmtList) => .K
 rule toSeq(S:Stmt ; SL:StmtList) => S ~> toSeq(SL)
 rule <k> { SL:StmtList ; } => toSeq(SL) ... </k>
 
 // ブロックは中のステートメント列をそのまま実行
 // rule <k> { SL:StmtList ;} => SL ... </k>
 
//   // print: 評価済みの Int を <out> に追加
 rule <k> print(I :Int) => .K ... </k>
 <out> OL => OL ListItem(I) </out>
//   
//   // 算術
 rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
 rule <k> I1:Int * I2:Int => I1 *Int I2 ... </k>

 syntax Bool ::= isKResult(K) [symbol(isKResult), function]
 rule isKResult(_:Int) => true
 rule isKResult(_) => false [owise]

endmodule
