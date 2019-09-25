`default_nettype none

module test;

    reg clk = 0;
    reg reset = 1;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0,test);
        # 1000000;
        $finish;

    end

    top top0( .clock_in(clk));

    /* Make a regular pulsing clock. */
    always #1 clk = !clk;

endmodule // test

