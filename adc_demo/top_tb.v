`default_nettype none

module test;

    reg clk = 0;
    reg reset = 1;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0,test);
        # 100000;
        $finish;

    end
    wire adc_cs;
    wire adc_clk;
    wire adc_ready;
    wire adc_sd;
    reg run = 1;
    wire done;

    top top0( .clock_in(clk), .adc_clk(adc_clk), .adc_cs(adc_cs), .adc_sd(adc_sd));
    adc_model #(.PERIOD(100)) adc_model_inst(.run(run), .clk(adc_clk), .cs(adc_cs), .sd(adc_sd), .done(done));

    /* Make a regular pulsing clock. */
    always #1 clk = !clk;

endmodule // test

