`default_nettype none
module ram #(
    parameter FONT_FILE = "BRAM_16.list",
    // 320 x 240 = 76.8k
    parameter addr_width = 17,
    parameter data_width = 8
    )
    (
    input clk,
    input [addr_width-1:0] addr,
    input [data_width-1:0] wdata,
    input w_enable,
    output [data_width-1:0] rdata
    );

    /*
    wire addr_low = addr[0];

    wire [15:0] rdata16;
    wire [13:0] addr14 = addr >> 1;
    assign rdata = addr_low ? rdata16[7:0] : rdata16[15:8];
    wire [15:0] wdata16 = addr_low ? {8'b0, wdata} : {wdata, 8'b0};
    wire [3:0] mask_wr = addr_low ? {4'b0011 } : {4'b1100 };
    */

    `ifndef DEBUG
     
	SB_SPRAM256KA spram (
		.ADDRESS(addr),
		.DATAIN(wdata),
		.MASKWREN(4'b1111),
		.WREN(w_enable),
		.CHIPSELECT(1'b1),
		.CLOCK(clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(rdata)
	);

    `endif
endmodule

