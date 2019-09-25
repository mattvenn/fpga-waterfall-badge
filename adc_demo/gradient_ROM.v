//////////////////////////////////////////////////////////////////////////////////
// Original Engineer: Juan Manuel Rico
//
//
//-----------------------------------------------------------------------------
//-- GPL license
//-----------------------------------------------------------------------------
module gradientROM 
#(
    parameter GRADIENT_FILE = "GRADIENT_COLOUR_24.hex",
    parameter addr_width = 8,
    parameter data_width = 24, 
)
(
    input wire                  clk,
    input wire [addr_width-1:0] addr,
    output reg [data_width-1:0] dout
);

reg [data_width-1:0] mem [(1 << addr_width)-1:0];

initial begin
  if (GRADIENT_FILE) $readmemh(GRADIENT_FILE, mem);
end

always @(posedge clk)
begin
    dout <= mem[addr];
end

endmodule
