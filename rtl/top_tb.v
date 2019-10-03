`default_nettype none
`timescale 1ns/1ns

module test;

    reg clk = 0;
    reg reset = 1;

    // adc wires
    wire adc_cs;
    wire adc_clk;
    wire adc_ready;
    wire adc_sd;
    reg run = 1;
    wire done;
    
    integer i;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0,test);
        /*
        for (i = 0 ; i < 320 ; i = i + 1) begin
            $dumpvars(1, top_0.sdft_0.samples[i]);
            $dumpvars(2, top_0.sdft_0.frequency_bins_real[i]);
            $dumpvars(3, top_0.sdft_0.frequency_bins_imag[i]);
            $dumpvars(4, top_0.freq_bram_0.ram[i]);
        end
            */
        # 5000000;
        $finish;

    end

    top #(
        .FREQ_BINS(64), 
        .LIMIT_BINS(32), 
        .H_VISIBLE(64),
        .V_VISIBLE(10),
        .GRADIENT_FILE("GRADIENT_GREY_24.hex")
        ) top_0( .clock_in(clk), .adc_mic_clk(adc_clk), .adc_mic_cs(adc_cs), .adc_mic_sd(adc_sd));

    // period is us 1000 = 0.001s = 1000hz
    adc_model #(.PERIOD(2000)) adc_model_0(.run(run), .clk(adc_clk), .cs(adc_cs), .sd(adc_sd), .done(done));

    // clock at 20MHz
    always #25 clk = !clk;

endmodule // test

