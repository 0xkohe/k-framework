module LESSON-02-D

  syntax Container ::= Jar(Fruit)
  syntax Fruit ::= Apple() | Pear()

  syntax Fruit ::= contentsOfJar(Container)

  rule contentsOfJar(Jar(F)) => F

endmodule
