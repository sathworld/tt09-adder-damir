module onebitfa (
    input  wire a,      // Operand A
    input  wire b,      // Operand B
    input  wire cin,    // Carry in
    output wire sum,    // Sum
    output wire cout    // Carry out
);

  // Internal components //
  // sum = a XOR b XOR cin
  xor xor1(sum, a, b, cin);                     // Take the XOR with fan in of 3 of a, b and cin and put the result in sum
  // cout = (a AND b) OR (cin AND (a XOR b)) = (a AND b) OR (cin AND b) OR (cin AND a)
  or or1(cout, (a & b), (cin & a), (cin & b)); // Take the OR with fan in of 3 of a&b, cin&a and cin&b and put the result in cout
endmodule