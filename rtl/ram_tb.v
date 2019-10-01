`default_nettype none

module test;

    reg clk = 0;
    reg reset = 1;
    reg [16:0] addr;
    reg [7:0] wdata;
    wire [7:0] rdata;
    reg w_enable;
    integer i;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0,test);

        // test address demux
        w_enable <= 1;
        for(i = 0; i < 3 * (2<<14); i ++) begin
            wdata <= i;
            addr <= i;
            #2;
        end

        #2;
        w_enable <= 0;
        for(i = 0; i < 3 * (2<<14); i ++) begin
            wdata <= i;
            addr <= i;
            #2;
        end
        
        $finish;

    end

    ram ram0( 
        .clk(clk),
        .addr(addr),
        .wdata(wdata),
        .w_enable(w_enable),
        .rdata(rdata)
    );

    /* Make a regular pulsing clock. */
    always #1 clk = !clk;

endmodule // test
