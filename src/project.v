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
  reg [7:0] ui_in_buf;
  wire [7:0] bus;
  wire nLa;
  wire Ea;
  wire nLb;
  wire Eb;
  wire Eu;
  wire [7:0] regA;
  wire [7:0] regB;
  wire sub;
  wire loading_onto_bus;
  wire CF;
  wire ZF;
  wire bus_regA_sel;
  
  // ui_in NEEDS A BUFFER
  always @(posedge clk) begin
    if (!loading_onto_bus)
      ui_in_buf <= 8'b00000000;
    else
      ui_in_buf <= ui_in;
  end
  assign bus = (loading_onto_bus) ? ui_in_buf : 8'bZZZZZZZZ;
  //assign bus = Ea ? busregA : (Eu ? busAdd : ui_in_buf);
  // assign bus = ena ? ui_in: 8'bZZZZZZZZ; // Input path
  assign uo_out = bus_regA_sel ? bus : regA; 
  
  
  // // All output pins must be assigned. If not used, assign to 0.
  assign uio_out[7] = 0;
  assign uio_out[6] = 0;
  assign uio_out[5] = 0;
  assign uio_out[4] = 0;
  assign uio_out[3] = 0;
  assign uio_out[2] = 0;
  assign uio_out[1] = 0;

  assign uio_oe[7] = 0;
  assign uio_oe[6] = 0;
  assign uio_oe[5] = 0;
  assign uio_oe[4] = 0;
  assign uio_oe[3] = 0;
  assign uio_oe[2] = 0;
  assign uio_oe[1] = 0;
  assign uio_oe[0] = 1;

  assign bus_regA_sel = uio_in[7];
  assign nLa = uio_in[6];
  assign nLb = uio_in[5];
  assign Ea = uio_in[4];
  assign Eb = 0;
  assign Eu = uio_in[3];
  assign sub = uio_in[2];
  assign loading_onto_bus = uio_in[1];
  // assign uio_out[1] = CF;
  assign uio_out[0] = ZF;


  alu aluobj(clk, Eu, regA, regB, sub, bus, CF, ZF);
  accumulator_register accumulatorobj(clk, bus, nLa, Ea, regA, rst_n);
  accumulator_register breg(clk, bus, nLb, Eb, regB, rst_n);
  // List all unused inputs to prevent warnings
  wire _unused = &{rst_n, ena, uio_in[1], uio_in[0], uio_in[6], uio_in[7], CF, 1'b0};

endmodule
