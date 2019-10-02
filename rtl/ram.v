`default_nettype none
module ram 
    #( 
        parameter DATA_W = 8,
        parameter ADDR_W = 17
    )
    (
    // 320 x 240 = 76.8k
    input clk,
    input [ADDR_W-1:0] addr,
    input [DATA_W-1:0] wdata,
    input w_enable,
    output reg [DATA_W-1:0] rdata
    );

    wire [2:0] n = addr[16:14];
    reg [3*4-1:0] wmask;
    wire [16*3-1:0] muxed_rdata;

    always @(posedge clk) begin
        rdata <= muxed_rdata >> {n, 3'b000}; // suggested by Clifford
        wmask <= 2'b11 << {n, 1'b0};  // suggested by Clifford
    end

    // wdata, double the data, the wmask selects which spram is written to
    wire [15:0] wdata16 = { wdata, wdata };

    // yosys doesn't yet support inference of sprams  
	SB_SPRAM256KA spram [0:2] (
		.ADDRESS(addr[13:0]),
		.DATAIN(wdata16),
		.MASKWREN(wmask),
		.WREN(w_enable),
		.CHIPSELECT(1'b1),
		.CLOCK(clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(muxed_rdata)
	);

endmodule
