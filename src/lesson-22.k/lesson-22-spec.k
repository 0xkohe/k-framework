requires "lesson-22.k"
requires "domains.md"

module LESSON-22-SPEC-SYNTAX
    imports LESSON-22-SYNTAX

// added
    syntax Id ::= "$a" [token]
    | "$b"  [token]
    | "$c"  [token]
    | "$n"  [token]
    | "$s"  [token]
    | "$sum"  [token]

endmodule

module VERIFICATION
    imports K-EQUAL
    imports LESSON-22-SPEC-SYNTAX
    imports LESSON-22
    imports MAP-SYMBOLIC

    rule { M:Map [ K <- V ] #Equals M [ K <- V' ] } => { V #Equals V' } [simplification]

endmodule

module LESSON-22-SPEC
    imports VERIFICATION

    claim <k> 3 + 4 => 7 ... </k>

    claim <k> if ( 3 + 4 == 7 ) {
            $a = 1 ;
            } else {
            $a = 2 ;
            }
        => . ... </k>
        <store> STORE => STORE [ $a <- 1 ] </store>


    claim <k> $a = A:Int ; $b = B:Int ;
          if ($a < $b) {
            $c = $b ;
          } else {
            $c = $a ;
          }
        => . ... </k>
        <store> STORE => STORE [ $a <- A ] [ $b <- B ] [ $c <- ?C:Int ] </store>
    ensures (?C ==Int A) orBool (?C ==Int B)

    claim
    <k>
        while ( 0 < $n ) {
            $s = $s + $n;
            $n = $n - 1;
            } => . ...
    </k>
    <store>
        $s |-> (S:Int => S +Int ((N +Int 1) *Int N /Int 2))
        $n |-> (N:Int => 0)
    </store>
    requires N >=Int 0

    claim
    <k>
        def $sum($n, .Ids) {
            $s = 0 ;
            while (0 < $n) {
                $s = $s + $n;
                $n = $n - 1;
            }
            return $s;
        }

        $s = $sum(N:Int, .Ints);
    => . ... </k>
    <funcs> .Map => ?_ </funcs>
    <store> $s |-> (_ => ((N +Int 1) *Int N /Int 2)) </store>
    <stack> .List </stack>
    requires N >=Int 0
endmodule
