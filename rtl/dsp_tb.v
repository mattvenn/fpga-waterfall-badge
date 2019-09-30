`default_nettype none

module test;

    reg clk = 0;
    reg reset = 1;
    reg [15:0] A = 8'd200;
    reg [15:0] B = 8'd0;
    wire [31:0] X;
    integer i = 0;
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0,test);
        for( i = 0; i < 100; i ++ ) begin
            B <= B + 3;
            # 2;
        end
        $finish;

    end

    dsp_mult_16 dsp_0 ( .clock(clk), .A(A), .B(B), .X(X));

    /* Make a regular pulsing clock. */
    always #1 clk = !clk;

endmodule // test


