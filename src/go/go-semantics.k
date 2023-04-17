requires "go-syntax.k"

module GO-SEMANTICS
    imports GO-SYNTAX
	 
    configuration <T>
                     <k> $PGM:Stmt </k>
                     <env> .Map </env>
                     <store> .Map </store>
                     <result> .K </result>
                  </T>

    rule <k> X:Id = I:Int ; => . ...</k>
         <env> E:Map => E[X <- L] </env>
         <store> S:Map => S[L <- I] </store>
         requires notBool (X in keys(E))
         fresh L

    rule <k> X:Id = E1:Exp + E2:Exp ; => X = I1 + I2 ...</k>
         <env> E:Map </env>
         <store> _:Map </store>
         where (I1:Int = E1) andBool (I2:Int = E2)

    rule <k> X:Id = E1:Exp * E2:Exp ; => X = I1 * I2 ...</k>
         <env> E:Map </env>
         <store> _:Map </store>
         where (I1:Int = E1) andBool (I2:Int = E2)

    rule <k> return E:Exp ; => . ...</k>
         <result> _:K => I:Int </result>
         where I = E
endmodule

