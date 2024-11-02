module alu (
    input  wire       clk, // Clock signal
    input  wire       enable_output, // Output result to the 8 bit bus when 1
    input  wire [7:0] reg_a, // Register A
    input  wire [7:0] reg_b, // Register B
    input  wire       sub, // Addition/Subtraction if 0/1
    output wire [7:0] bus, // Connection to the bus
    output reg        CF, // Carry out flag
    output reg        ZF // Indicates if the result of the sum is 0
);
  wire carry_out;
  wire res_zero;
  wire [7:0] sum;
  add_sub_8bit addsub(reg_a, reg_b, sub, sum, carry_out, res_zero);
  assign bus = enable_output ? sum : 8'bZZZZZZZZ; // Tri-state buffer to connect to the bus;
  always @(posedge clk) begin
    if (enable_output) begin
      CF <= carry_out;
      ZF <= res_zero;
    end
  end
endmodule
