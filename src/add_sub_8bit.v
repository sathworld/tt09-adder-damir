module add_sub_8bit (
    input  wire [7:0] op_a,       // Operand A (8 bits)
    input  wire [7:0] op_b,       // Operand B (8 bits)
    input  wire       sub,        // Addition/Subtraction if 0/1
    output wire [7:0] sum,        // Sum (8 bits)
    output wire       carry_out,  // Carry out
    output wire       res_zero    // Result is zero
);

  genvar i;                               // Will be used to generate circuitry for bits 7-0

  // Internal signals //
  wire [7:0] b_xor_sub;                   // Signal for taking 2s complement of Operand B
  wire [8:0] carry_array;                 // Signal for storing the initial carry in and generated carry out
  
  // Generate initial carry in //
  assign carry_array[0] = sub;            // Add 1 to perform 2s complement of Operand B if needed
  
  // Generate circuitry for bits 7-0 //
  generate
  for (i = 0; i < 8; i = i + 1) begin     // Generate circuitry for bits 7-0
    assign b_xor_sub[i] = op_b[i] ^ sub;  // Invert the bits of operand B if sub is 1, otherwise keep operand B the same
    // Implement a ripple 8 bit adder using 8 full adders //
    onebitfa fa (
        .a(op_a[i]),                      // Operand A (bit i) (1 bit)
        .b(b_xor_sub[i]),                 // Operand B (bit i) (1 bit)
        .cin(carry_array[i]),             // Carry in (bit i) (1 bit)
        .sum(sum[i]),                     // Sum (bit i) (1 bit)
        .cout(carry_array[i+1])           // Carry out (bit i+1) (1 bit)
      ); 
  end
  endgenerate
  
  // Generate flags //
  assign carry_out = carry_array[8];      // Set carry out to be the last value of the array of the carries
  assign res_zero = ~|sum;                // Reduce the sum signal with NOR to detect if any of the bits were 1
  
endmodule