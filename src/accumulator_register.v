module accumulator_register (
    input  wire       clk, // Clock signal
    inout  wire [7:0] bus,
    input  wire       load, // Load into regA from the 8 bit bus when 0,
    input  wire       enable_output, // Output regA to the 8 bit bus when 1,
    output reg  [7:0] regA,
    input  wire       rst_n
);

  always @(posedge clk or negedge rst_n) begin
      if (!rst_n)
         regA <= 8'b00000000;
      else
      if (!load)
        regA <= bus;
  end
  assign bus = enable_output ? regA : 8'bZZZZZZZZ; // Tri-state buffer to connect to the bus;
  
endmodule