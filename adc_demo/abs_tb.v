`default_nettype none
`timescale 1ns/1ns

module test;

    wire [15:0] a;
    reg [15:0] r, i;
    

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0,test);

        r <= +5800;
        i <= +5800;
        # 10

        r <= +2000;
        i <= +1000;
        # 10

//////
        r <= -1000;
        i <= -2000;
        # 10

        r <= -2000;
        i <= -1000;
        # 10

//////
        r <= -1000;
        i <= +2000;
        # 10

        r <= -2000;
        i <= +1000;
        # 10

//////
        r <= +1000;
        i <= -2000;
        # 10

        r <= +2000;
        i <= -1000;
        # 10

        $finish;

    end

    abs #(.width(16)) abs_0 (.r(r), .i(i), .a(a));

endmodule // test


