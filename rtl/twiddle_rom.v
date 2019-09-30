`default_nettype none
module twiddle_rom 
#(
    parameter FILE_REAL = "twiddle_real.list",
    parameter FILE_IMAJ = "twiddle_imag.list",
    parameter ADDR_W    = 9,
    parameter DATA_W    = 8
)
(
    input wire                  clk,
    input wire [ADDR_W-1:0]     addr,
    output reg signed [15:0]     dout_real,
    output reg signed [15:0]     dout_imag
);

    reg signed [DATA_W-1:0] rom_real [(1 << ADDR_W)-1:0];
    reg signed [DATA_W-1:0] rom_imag [(1 << ADDR_W)-1:0];

    initial begin
        if (FILE_REAL) $readmemh(FILE_REAL, rom_real);
        if (FILE_IMAJ) $readmemh(FILE_IMAJ, rom_imag);
    end

    always @(posedge clk) begin
        dout_real = rom_real[addr];
        dout_imag = rom_imag[addr];
    end

endmodule
