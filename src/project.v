/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule

module accumulator (
    input  wire       clk, // Clock signal
    inout  wire [7:0] bus,
    input  wire       load,
    input  wire       enable_output,
    output reg  [7:0] regA
);

  always @(posedge clk ) begin
    if (load)
        regA <= bus;
  end
  assign bus = enable_output ? regA : 8'bZZZZZZZZ; // Tri-state buffer to connect to the bus;
  
endmodule




module add_sub_8bit_sync (
    input  wire       clk, // Clock signal
    input  wire       enable_output, // Output result to the 8 bit bus when 1
    input  wire [7:0] reg_a, // Register A
    input  wire [7:0] reg_b, // Register B
    input  wire       sub, // Addition/Subtraction if 0/1
    output wire [7:0] bus, // Connection to the bus
    output reg       CF, // Carry out flag
    output reg       ZF // Indicates if the result of the sum is 0
);
  wire carry_out;
  wire res_zero;
  wire [7:0] sum;
  add_sub_8bit addsub(reg_a, reg_b, sub, sum, carry_out, res_zero);
  assign bus = enable_output ? sum : 8'bZZZZZZZZ; // Tri-state buffer to connect to the bus;
  always @(posedge clk ) begin
    if (enable_output)
        CF <= carry_out;
        ZF <= res_zero;
  end
endmodule



// Unsyncronized 8 bit adder/subtractor
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