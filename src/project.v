/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_adder_accumulator_sathworld (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire [7:0] bus;
  wire nLa;
  wire Ea;
  wire Eu;
  wire [7:0] regA;
  wire [7:0] regB;
  wire sub;
  wire CF;
  wire ZF;
  
  
  assign bus = uio_in[0] ? uo_in : 8'bz; // Input path
  assign uo_out = bus; 
  
  
  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;
  assign nLa = uio_in[1];
  assign Ea = uio_in[2];
  assign Eu = uio_in[3];
  assign regB = 0;
  assign sub = uio_in[4];

  alu aluobj(clk, Eu, regA, regB, sub, bus, CF, ZF);
  accumulator_register accumulatorobj(clk, bus, nLa, Ea, regA);
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, rst_n, 1'b0};

endmodule
