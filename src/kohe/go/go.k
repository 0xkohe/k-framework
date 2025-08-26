requires "domains.md"


module GO-SYNTAX
  imports INT-SYNTAX
  
  
  syntax Program ::= "package" "main" "func" "main" "(" ")" Block
  syntax Block ::= "{" StmtList "}"
  syntax StmtList ::= List{Stmt, ""}
  syntax Stmt ::= Print | Block
  
  
  syntax Print ::= "print" "(" Exp ")"  [strict]
  
  
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
 rule <k> { SL:StmtList } => SL ... </k>
 rule <k> S1:Stmt S2:StmtList => S1 ~> S2 ... </k>
 // rule <k> S:Stmt => .K ... </k>
 rule <k> .StmtList => .K ... </k>

 
 // print: 評価済みの Int を <out> に追加
 rule <k> print(I :Int) => .K ... </k>
 <out> OL => OL ListItem(I) </out>

 rule <k> print(I :Exp => I) ... </k>
 
 
 // () の除去
 rule (E:Exp) => E
 
 
 // 算術
 rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
 rule <k> I1:Int * I2:Int => I1 *Int I2 ... </k>

 syntax Bool ::= isKResult(K) [symbol(isKResult), function]
 rule isKResult(_:Int) => true
 rule isKResult(_) => false [owise]

endmodule
