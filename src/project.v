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
  wire nLb;
  wire Eb;
  wire Eu;
  wire [7:0] regA;
  wire [7:0] regB;
  wire sub;
  wire CF;
  wire ZF;
  
  
//  assign bus = ui_in; // Input path
  assign uo_out = uio_in[0] ? ui_in : regA; 
  
  
  // // All output pins must be assigned. If not used, assign to 0.
  assign uio_out[0] = 0;
  assign uio_out[1] = 0;
  assign uio_out[2] = 0;
  assign uio_out[3] = 0;
  assign uio_out[4] = 0;
  assign uio_out[5] = 0;

  assign uio_oe[0] = 0;
  assign uio_oe[1] = 0;
  assign uio_oe[2] = 0;
  assign uio_oe[3] = 0;
  assign uio_oe[4] = 0;
  assign uio_oe[5] = 0;
  assign uio_oe[6] = 1;
  assign uio_oe[7] = 1;

  assign nLa = uio_in[1];
  assign nLb = uio_in[2];
  assign Ea = uio_in[3];
  assign Eb = 0;
  assign Eu = uio_in[4];
  assign sub = uio_in[5];
  // assign nLa = 1;
  // assign nLb = 1;
  // assign Ea = 0;
  // assign Eb = 0;
  // assign Eu = 0;
  // assign sub = 0;
  assign uio_out[6] = CF;
  assign uio_out[7] = ZF;


  alu aluobj(clk, Eu, regA, regB, sub, bus, CF, ZF);
  accumulator_register accumulatorobj(clk, bus, nLa, Ea, regA);
//  accumulator_register breg(clk, bus, nLb, Eb, regB);
  assign regB = regA;
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, rst_n, uio_in[6], uio_in[7], 1'b0};

endmodule
