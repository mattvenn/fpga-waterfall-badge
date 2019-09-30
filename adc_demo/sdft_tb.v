`default_nettype none
module test;

    localparam HIGH = 200;
    localparam LOW  = 0;
    localparam DATA_W = 8;
    localparam FREQ_BINS = 64;
    localparam RUN_LENGTH = 300;
    localparam SAMPLE_PERIOD = 5;

    reg reset = 0;
    reg [DATA_W-1:0] fft_sample = 0;
    reg fft_start = 0;

    reg [16:0] fft_cycles = 0;
    reg [10:0] sample_counter = 0;
    wire fft_ready;
    reg fft_read = 0;

    always @(posedge clk) begin
        sample_counter <= sample_counter + 1;
        if(sample_counter == SAMPLE_PERIOD) begin
            sample_counter <= 0;
            if(fft_sample == HIGH)
                fft_sample <= LOW;
            else
                fft_sample <= HIGH;
        end
    end

    integer i, j;
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0,test);
        for (i = 0 ; i < FREQ_BINS ; i = i + 1) begin
            $dumpvars(1, sdft_0.samples[i]);
            $dumpvars(2, sdft_0.frequency_bins_real[i]);
            $dumpvars(3, sdft_0.frequency_bins_imag[i]);
        end

        while(fft_cycles < RUN_LENGTH) begin
            fft_cycles <= fft_cycles + 1;
            $display("run cycle: %d %d", fft_cycles, fft_sample);
            wait(fft_ready == 1);
            fft_start <= 1;
            wait(fft_ready == 0);
            fft_start <= 0;
        end

        wait(fft_ready == 1);

        fft_cycles <= 0;
        fft_read <= 1;
        #2;
        while(fft_cycles < FREQ_BINS) begin
            # 4;
            $display("read bin: %d", fft_cycles);
            fft_cycles <= fft_cycles + 1;
        end
        #2;
        fft_read <= 0;

        $finish;
    end

    // clock
    reg clk = 0;
    always #1 clk = !clk;

    sdft #(.data_w(DATA_W), .freq_bins(FREQ_BINS), .freq_w(DATA_W*2)) sdft_0(.clk (clk), .sample(fft_sample), .ready(fft_ready), .start(fft_start), .read(fft_read), .bin_addr(fft_cycles)); 

endmodule // test
