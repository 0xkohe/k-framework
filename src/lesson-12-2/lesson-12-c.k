requires "lesson-12-b.k"

module LESSON-12-C
  imports LESSON-12-B
  imports INT

  syntax Int ::= sum(Ints) [function]
  rule sum(I:Int) => I
  rule sum(I1:Int, I2:Int) => I1 +Int I2
  rule sum(I1:Int, I2:Int, Is:Ints) => sum(I1 +Int I2, Is)
endmodule