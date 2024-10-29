// 1 bit FullAdder
module onebitfa (a, b, cin, sum, cout);
    input  wire a; // Operand A
    input  wire b; // Operand B
    input  wire cin; // Carry in
    output wire sum; // Sum
    output wire cout; // Carry out

    xor xor1(sum, a, b, cin); // Take the XOR with fan in of 3 of a, b and cin and put the result in sum
    or or1(cout, (a & b), (cin & a), (cin & b)); // Take the OR with fan in of 3 of a&b, cin&a and cin&b and put the result in cout
endmodule