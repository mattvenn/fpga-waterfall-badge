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

    `ifndef DEBUG
   reg [3:0] wmask1, wmask2, wmask3;
   always @(*)
       case({w_enable, addr[16:14]})
           4'b1000: begin wmask1 = 4'b0011; wmask2 = 4'b0; wmask3 = 4'b0; end
           4'b1001: begin wmask1 = 4'b1100; wmask2 = 4'b0; wmask3 = 4'b0; end
           4'b1010: begin wmask2 = 4'b0011; wmask1 = 4'b0; wmask3 = 4'b0; end
           4'b1011: begin wmask2 = 4'b1100; wmask1 = 4'b0; wmask3 = 4'b0; end
           4'b1100: begin wmask3 = 4'b0011; wmask1 = 4'b0; wmask2 = 4'b0; end
           4'b1101: begin wmask3 = 4'b1100; wmask1 = 4'b0; wmask2 = 4'b0; end
           default: begin wmask1 = 4'b0000; wmask2 = 4'b0; wmask3 = 4'b0; end
       endcase

   wire [15:0] rdata1, rdata2, rdata3;

   // rdata demux
   always @(*)
       case({addr[16:14]})
           3'b000: rdata = rdata1[ 7:0];
           3'b001: rdata = rdata1[15:8];
           3'b010: rdata = rdata2[ 7:0];
           3'b011: rdata = rdata2[15:8];
           3'b100: rdata = rdata3[ 7:0];
           3'b101: rdata = rdata3[15:8];
           default:rdata = 8'b0;
       endcase
   /*
   // fails timing
  assign rdata = (addr[16:14] == 3'b000) ? rdata1[ 7:0] :
                 (addr[16:14] == 3'b001) ? rdata1[15:8] :
                 (addr[16:14] == 3'b010) ? rdata2[ 7:0] :
                 (addr[16:14] == 3'b011) ? rdata2[15:8] :
                 (addr[16:14] == 3'b100) ? rdata3[ 7:0] :
                 (addr[16:14] == 3'b101) ? rdata3[15:8] :
                 8'b0;
   */
       
   // wdata, double the data, the wmask selects which spram is written to
   wire [15:0] wdata16 = { wdata, wdata };

     
	SB_SPRAM256KA spram_1 (
		.ADDRESS(addr[13:0]),
		.DATAIN(wdata16),
		.MASKWREN(wmask1),
		.WREN(w_enable),
		.CHIPSELECT(1'b1),
		.CLOCK(clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(rdata1)
	);

	SB_SPRAM256KA spram_2 (
		.ADDRESS(addr[13:0]),
		.DATAIN(wdata16),
		.MASKWREN(wmask2),
		.WREN(w_enable),
		.CHIPSELECT(1'b1),
		.CLOCK(clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(rdata2)
	);

	SB_SPRAM256KA spram_3 (
		.ADDRESS(addr[13:0]),
		.DATAIN(wdata16),
		.MASKWREN(wmask3),
		.WREN(w_enable),
		.CHIPSELECT(1'b1),
		.CLOCK(clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(rdata3)
	);

    `else
    reg [DATA_W-1:0] ram [(1 << ADDR_W)-1:0];
    always @(posedge clk) begin
        if(w_enable)
            ram[addr] <= wdata;
        else
            rdata <= ram[addr];
    end
    `endif
endmodule

