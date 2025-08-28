requires "domains.md"


module GO-SYNTAX
  imports INT-SYNTAX
  
  
  syntax Program ::= "package" "main" "func" "main" "(" ")" Block
  // syntax Block ::= "{" StmtList "}"
  syntax Block ::= "{" Stmt "}"
  // syntax StmtList ::= List{Stmt, ""}
  syntax Stmt ::= Print | Block
  syntax Stmt ::= Stmt Stmt                          [right]

  syntax Print ::= "print" "(" Exp ")" ";"  [strict]
  
  
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
 
 
 // ブロックは中のステートメント列をそのまま実行
 rule <k> { SL:Stmt } => SL ... </k>
 rule S1:Stmt S2:Stmt => S1 ~> S2
 
//   // print: 評価済みの Int を <out> に追加
 rule <k> print(I :Int); => .K ... </k>
 <out> OL => OL ListItem(I) </out>
//   
//   // 算術
 rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
 rule <k> I1:Int * I2:Int => I1 *Int I2 ... </k>

 syntax Bool ::= isKResult(K) [symbol(isKResult), function]
 rule isKResult(_:Int) => true
 rule isKResult(_) => false [owise]

endmodule
