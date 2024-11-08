/*
 * Copyright (c) 2024 Damir Gazizullin; Owen Golden
 * SPDX-License-Identifier: Apache-2.0
 */

module alu (
    input  wire       clk,            // Clock signal (Rising edge) (needed for storing CF and ZF)
    input  wire       enable_output,  // Enable ALU output to the bus (ACTIVE-HIGH)
    input  wire [7:0] reg_a,          // Register A (8 bits)
    input  wire [7:0] reg_b,          // Register B (8 bits)
    input  wire       sub,            // Perform addition when 0, perform subtraction when 1
    output wire [7:0] bus,            // Bus (8 bits)
    output reg        CF,             // Carry Flag
    output reg        ZF              // Zero Flag
);
  // ALU Internal signals //
  wire carry_out; // Carry out from the 8-bit adder/subtractor
  wire res_zero;  // Result is zero
  wire [7:0] sum; // Result of the 8-bit adder/subtractor

  // 8 Bit Adder/Subtractor instantiation //
  add_sub_8bit addsub(
      .op_a(reg_a),           // Register A
      .op_b(reg_b),           // Register B
      .sub(sub),              // Perform addition when 0, perform subtraction when 1
      .sum(sum),              // Result of the 8-bit adder/subtractor
      .carry_out(carry_out),  // Carry out from the 8-bit adder/subtractor
      .res_zero(res_zero)     // Result is zero
  );

  // Tri-state buffer to connect to the bus //
  assign bus = enable_output ? sum : 8'bZZZZZZZZ; // Tri-state buffer to connect to the bus;
  
  // Flags //
  always @(posedge clk) begin // Clock (Rising edge)
    if (enable_output) begin  // Allow the flags to be updated only when the ALU output is enabled
      CF <= carry_out;        // Carry Flag <= Carry out from the 8-bit adder/subtractor
      ZF <= res_zero;         // Zero Flag <= Result is zero
    end
  end
endmodule
