/*
 * Copyright (c) 2024 Damir Gazizullin; Owen Golden
 * SPDX-License-Identifier: Apache-2.0
 */

module accumulator_register (
    input  wire       clk,            // Clock (Rising edge)
    inout  wire [7:0] bus,            // Bus (8 bits)
    input  wire       load,           // Enable ALU output to the bus (ACTIVE-HIGH)
    input  wire       enable_output,  // Output regA to the 8 bit bus when 1,
    output reg  [7:0] regA,           // Register A (8 bits)
    input  wire       rst_n           // Reset (ACTIVE-LOW)
);
  // Accumulator Register //
  always @(posedge clk or negedge rst_n) begin // Update on Clock (Rising edge) or Reset (Fallling edge)
      if (!rst_n)                              // Reset regA to 0 when rst_n is low
        regA <= 8'b00000000;
      else if (!load)                          // Load regA from the bus when load is low (ACTIVE-LOW)                         
        regA <= bus;
  end
  // Tri-state buffer to connect to the bus //
  assign bus = enable_output ? regA : 8'bZZZZZZZZ; // Tri-state buffer to connect to the bus;
  
endmodule