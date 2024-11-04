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
  reg [7:0] ui_in_buf;          // Buffer for ui_in (8 bits)
  wire [7:0] bus;               // Bus (8 bits) (High impedance when not in use)
  wire nLa;                     // enable Accumulator Register load from bus (ACTIVE-LOW)
  wire Ea;                      // enable Accumulator Register output to the bus (ACTIVE-HIGH)
  wire nLb;                     // enable B Register load from bus (ACTIVE-LOW)
  wire Eb;                      // enable B Register output to the bus (ACTIVE-HIGH)
  wire Eu;                      // enable ALU output to the bus (ACTIVE-HIGH)
  wire [7:0] regA;              // Accumulator Register (8 bits)
  wire [7:0] regB;              // B Register (8 bits)
  wire sub;                     // perform addition when 0, perform subtraction when 1
  wire loading_onto_bus;        // Load the bus with the value from ui_in (ACTIVE-HIGH)
  wire CF;                      // Carry Flag
  wire ZF;                      // Zero Flag
  wire bus_regA_sel;            // Select uo_put to be regA when 0 or bus when 1
  
  // ui_in NEEDS A BUFFER
  // Buffer the input make gltest pass
  always @(posedge clk) begin
    // Buffer the input
    if (!loading_onto_bus)      // Load the input onto the bus if loading_onto_bus is high
      ui_in_buf <= 8'b00000000; // Set to 0 when not loading onto the bus
    else
      ui_in_buf <= ui_in;       // Load the input onto the bus
  end
  // Tri-state buffer to connect ui_in to the bus //
  assign bus = (loading_onto_bus) ? ui_in_buf : 8'bZZZZZZZZ;
  // Tri-state buffer to connect uo out to regA when 0 or bus when 1
  assign uo_out = bus_regA_sel ? bus : regA; 
  
  
  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out[7] = 0; // Unused
  assign uio_out[6] = 0; // Unused
  assign uio_out[5] = 0; // Unused
  assign uio_out[4] = 0; // Unused
  assign uio_out[3] = 0; // Unused
  assign uio_out[2] = 0; // Unused
  assign uio_out[1] = 0; // Unused

  // Configure the IOs //
  assign uio_oe[7] = 0;  // Set IO[7] to be an input
  assign uio_oe[6] = 0;  // Set IO[6] to be an input
  assign uio_oe[5] = 0;  // Set IO[5] to be an input
  assign uio_oe[4] = 0;  // Set IO[4] to be an input
  assign uio_oe[3] = 0;  // Set IO[3] to be an input
  assign uio_oe[2] = 0;  // Set IO[2] to be an input
  assign uio_oe[1] = 0;  // Set IO[1] to be an input
  assign uio_oe[0] = 1;  // Set IO[0] to be an output

  // Configure the control signals //
  assign bus_regA_sel = uio_in[7];      // Select uo_put to be regA when 0 or bus when 1
  assign nLa = uio_in[6];               // enable Accumulator Register load from bus (ACTIVE-LOW)
  assign nLb = uio_in[5];               // enable B Register load from bus (ACTIVE-LOW)
  assign Ea = uio_in[4];                // enable Accumulator Register output to the bus (ACTIVE-HIGH)
  assign Eb = 0;                        // B is never output to the bus
  assign Eu = uio_in[3];                // enable ALU output to the bus (ACTIVE-HIGH)
  assign sub = uio_in[2];               // perform addition when 0, perform subtraction when 1
  assign loading_onto_bus = uio_in[1];  // Load the bus with the value from ui_in (ACTIVE-HIGH)
  // assign uio_out[1] = CF;            // Carry Flag (DEPRECATED in favor of loading_onto_bus)
  assign uio_out[0] = ZF;               // Zero Flag

  // Instantiate the modules //

  // ALU //
  alu aluobj(
      .clk(clk),            // Clock (Rising edge) (needed for storing CF and ZF)
      .enable_output(Eu),   // Enable ALU output to the bus (ACTIVE-HIGH)
      .reg_a(regA),         // Register A (8 bits)
      .reg_b(regB),         // Register B (8 bits)
      .sub(sub),            // Perform addition when 0, perform subtraction when 1
      .bus(bus),            // Bus (8 bits)
      .CF(CF),              // Carry Flag
      .ZF(ZF)               // Zero Flag
  );

  // Accumulator Register //
  accumulator_register accumulatorobj(
      .clk(clk),            // Clock (Rising edge)
      .bus(bus),            // Bus (8 bits)
      .load(nLa),           // Enable Accumulator Register load from bus (ACTIVE-LOW)
      .enable_output(Ea),   // Enable Accumulator Register output to the bus (ACTIVE-HIGH)
      .regA(regA),          // Register A (8 bits)
      .rst_n(rst_n)         // Reset (ACTIVE-LOW)
  );
  
  // B Register //
  accumulator_register breg(
      .clk(clk),            // Clock (Rising edge)
      .bus(bus),            // Bus (8 bits)
      .load(nLb),           // Enable B Register load from bus (ACTIVE-LOW)
      .enable_output(Eb),   // Enable B Register output to the bus (ACTIVE-HIGH)
      .regA(regB),          // Register B (8 bits)
      .rst_n(rst_n)         // Reset (ACTIVE-LOW)
  );
  // List all unused inputs to prevent warnings
  wire _unused = &{rst_n, ena, uio_in[1], uio_in[0], uio_in[6], uio_in[7], CF, 1'b0};

endmodule
