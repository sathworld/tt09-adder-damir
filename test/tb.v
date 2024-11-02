`default_nettype none
`timescale 1ns / 1ps
/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/

module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

//  Wire up the inputs and outputs:
reg clk;
reg rst_n;
reg ena;
reg [7:0] ui_in;
reg [7:0] uio_in;
wire [7:0] uo_out;
wire [7:0] uio_out;
reg [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

// Replace tt_um_example with your module name:
tt_um_adder_accumulator_sathworld user_project (
// Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
);

// reg clk; // Clock signal
// reg [7:0] bus;
// reg load;
// reg enable_output;
// wire [7:0] regA;

// accumulator_register user_project(
//     .clk    (clk),      // clock
//     .bus    (bus),
//     .load   (load),
//     .enable_output (enable_output),
//     .regA   (regA)
// );


// reg       clk; // Clock signal
// reg       enable_output; // Output result to the 8 bit bus when 1
// reg [7:0] reg_a; // Register A
// reg [7:0] reg_b; // Register B
// reg       sub; // Addition/Subtraction if 0/1
// reg [7:0] bus; // Connection to the bus
// wire      CF; // Carry out flag
// wire      ZF; // Indicates if the result of the sum is 0


// alu user_project(
//     .clk    (clk),      // clock
//     .enable_output (enable_output),
//     .reg_a  (reg_a),
//     .reg_b  (reg_b),
//     .sub    (sub),
//     .bus    (bus),
//     .CF     (CF),
//     .ZF     (ZF)
// );

endmodule
