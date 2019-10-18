`default_nettype none
module bram
#(
    parameter ADDR_W    = 9,
    parameter DATA_W    = 8,
    parameter FILE      = 0,
    parameter ZERO      = 0
)
(
    input wire                  r_clk,
    input wire                  w_clk,
    input wire [ADDR_W-1:0]     r_addr,
    input wire [ADDR_W-1:0]     w_addr,
    input wire                  w_en,
    input wire                  r_en,
    input wire [DATA_W-1:0]     d_in,
    output reg [DATA_W-1:0]     d_out
);

    reg [DATA_W-1:0] bram [(1 << ADDR_W)-1:0];

    integer j;
    initial begin
        if (FILE) $readmemh(FILE, bram);
        if (ZERO)
            for(j = 0; j < (2<<ADDR_W); j = j + 1)  begin
                bram[j] = 0;
            end
        `ifdef DEBUG
        d_out = 0;
        `endif
    end

    always @(posedge w_clk) begin
        if(w_en)
            bram[w_addr] <= d_in;
    end

    always @(posedge r_clk) begin
        if(r_en)
            d_out <= bram[r_addr];
    end

endmodule

