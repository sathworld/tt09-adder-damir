// Combinational 8 bit adder/subtractor
module add_sub_8bit (
    input  wire [7:0] op_a, // Operand A
    input  wire [7:0] op_b, // Operand B
    input  wire       sub, // Addition/Subtraction if 0/1
    output wire [7:0] sum, // Result of the operation
    output wire       carry_out, // Carry out
    output wire       res_zero // Indicates if the result of the sum is 0
);

  genvar i; // Will be used to generate circuitry for bits 7-0
  
  wire [7:0] b_xor_sub; // Signal for taking 2s complement of Operand B
  wire [8:0] carry_array; // Signal for storing the initial carry in and generated carry out
  
  assign carry_array[0] = sub; // Set carry in to be sub (as taking 2s complement requires to invert the bits of the number and add 1), effectively adding 1
  
  generate
  for (i = 0; i < 8; i = i + 1) begin // Generate circuitry  for bits 7-0
    assign b_xor_sub[i] = op_b[i] ^ sub; // Invert the bits of operand B if sub is 1, otherwise keep operand B the same
    onebitfa fa (op_a[i], b_xor_sub[i], carry_array[i], sum[i], carry_array[i+1]); // Implement a ripple 8 bit adder using 8 full adders
  end
  endgenerate
  
  assign carry_out = carry_array[8]; // Set carry out to be the last value of the array of the carries
  assign res_zero = ~|sum; // Reduce the sum signal with NOR to detect if any of the bits were 1
  
endmodule