`default_nettype none
module spram 
    #( 
        parameter DATA_W = 8,
        parameter ADDR_W = 17
    )
    (
    // 320 x 240 = 76.8k
    input wire clk,
    input wire [ADDR_W-1:0] addr,
    input wire [DATA_W-1:0] w_data,
    input wire w_en,
    output reg [DATA_W-1:0] r_data
    );

    wire [2:0] n = addr[16:14];
    reg [3*4-1:0] wmask;
    wire [16*3-1:0] muxed_r_data;

    always @(posedge clk) begin
        r_data <= muxed_r_data >> {n, 3'b000}; // suggested by Clifford
        wmask <= 2'b11 << {n, 1'b0};  // suggested by Clifford
    end

    // w_data, double the data, the wmask selects which spram is written to
    wire [15:0] w_data16 = { w_data, w_data };

    // yosys doesn't yet support inference of sprams  
	SB_SPRAM256KA spram [0:2] (
		.ADDRESS(addr[13:0]),
		.DATAIN(w_data16),
		.MASKWREN(wmask),
		.WREN(w_en),
		.CHIPSELECT(1'b1),
		.CLOCK(clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(muxed_r_data)
	);

    `ifdef FORMAL
    // https://zipcpu.com/zipcpu/2018/07/13/memories.html
    
    reg f_past_valid = 0;
    always @(posedge clk)
        f_past_valid <= 1;

    // allow solver to pick any address
    (* anyconst *) wire [ADDR_W-1:0] f_addr;
    // make a data variable
    reg [DATA_W-1:0] f_data;

    // set data variable to whats in the bram
    initial begin
        assume(f_data == spram[0].mem[f_addr]);
    end

    always @(*)
        assume(n == 0);
     
    // always assert that the data at the address is correct
    always @(*)
        assert(spram[0].mem[f_addr] == f_data);

    always @(posedge clk) 
        if ((f_past_valid)
            // if a read  
            &&($past(addr == f_addr)))
        // assert the read gives correct answer
        assert(r_data == $past(f_data));

    always @(posedge clk)
            // if a write  
            if((w_en)
            // and at the special address
            &&(addr == f_addr))
        // update the data
        f_data <= w_data;
    `endif

endmodule
