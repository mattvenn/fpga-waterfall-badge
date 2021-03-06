`default_nettype none
module sdft
#(
    parameter DATA_W = 8, 
    parameter FREQ_BINS = 64, // 320
    parameter FREQ_W    = 16,
    parameter TWID_W = 10,
    parameter LIMIT_BINS = 32,
    parameter FILE_REAL = "twiddle_real.list",
    parameter FILE_IMAJ = "twiddle_imag.list"
)
(
    input wire                              clk,
    input wire [DATA_W-1:0]                 sample,
    input wire                              start,
    input wire                              read,
    input wire [BIN_ADDR_W-1:0]             bin_addr,

    output reg [FREQ_W-1:0]                 bin_out,
    output wire                             ready
);
    
    // width of addr needed to address the frequency bins
    localparam BIN_ADDR_W = $clog2(LIMIT_BINS);

    localparam SAMP_ADDR_W = $clog2(FREQ_BINS);

    // register for the twiddle factor ROM
    reg [BIN_ADDR_W-1:0] tw_addr;

    // register for sample index
    reg [SAMP_ADDR_W-1:0] sample_index;

    // twiddle factor ROM
    wire signed [FREQ_W-1:0] twid_real;
    wire signed [FREQ_W-1:0] twid_imag;

    twiddle_rom #(.ADDR_W(BIN_ADDR_W), .DATA_W(TWID_W)) twiddle_rom_0(.clk(clk), .addr(tw_addr), .dout_real(twid_real), .dout_imag(twid_imag));
//    bram #(.FILE("twiddle_real.list"), .ADDR_W(BIN_ADDR_W), .DATA_W(TWID_W)) twiddle_real (.r_clk(clk), .r_addr(tw_addr), .r_data_signed(twid_real), .r_en(1'b1));
//    bram #(.FILE("twiddle_imag.list"), .ADDR_W(BIN_ADDR_W), .DATA_W(TWID_W)) twiddle_imaj (.r_clk(clk), .r_addr(tw_addr), .r_data_signed(twid_imag), .r_en(1'b1));

    // frequency bins RAM - these get inferred as BRAMs
    reg signed [FREQ_W-1:0] frequency_bins_real [LIMIT_BINS-1:0];
    reg signed [FREQ_W-1:0] frequency_bins_imag [LIMIT_BINS-1:0];


    // sample storage
    reg [DATA_W-1:0] samples [FREQ_BINS-1:0];

    // delta storage (1 more than DATA_Width to handle subtraction)
    reg signed [DATA_W:0] delta;

    integer j;
    initial begin
        $display("LIMIT_BINS %d", LIMIT_BINS);
        $display("BIN_ADDR_W %d", BIN_ADDR_W);
        $display("SAMP_ADDR_W %d", SAMP_ADDR_W);
        `ifdef DEBUG
        tw_addr = 0; // can't have initial begin or BRAM won't infer
        sample_index = 0;
        delta = 0;
        for(j = 0; j < LIMIT_BINS; j = j + 1)  begin
            frequency_bins_real[j] <= 0;
            frequency_bins_imag[j] <= 0;
        end
        for(j = 0; j < FREQ_BINS; j = j + 1)  begin
            samples[j] <= 0;
        end
        `endif
        
    end

    localparam STATE_WAIT           = 0;
    localparam STATE_START          = 1;
    localparam STATE_READ           = 2;
    localparam STATE_CALC_1         = 3;
    localparam STATE_CALC_2         = 4;
    localparam STATE_CALC_3         = 5;
    localparam STATE_FINISH         = 6;

    reg [3:0] state = STATE_WAIT;

    assign ready = (state == STATE_WAIT) ? 1'b1 : 1'b0;

    reg signed [FREQ_W-1:0] bin_real, bin_imag;

    wire signed [31:0] f1, f2, f3, f4;
    wire signed [32:0] real_part, imag_part, scaled_real_part, scaled_imag_part;
    assign real_part = f1 - f2;
    assign imag_part = f3 + f4;
    assign scaled_real_part = real_part >>> (TWID_W-1);
    assign scaled_imag_part = imag_part >>> (TWID_W-1);
    wire [FREQ_W-1:0] abs_out;
    abs #(.width(FREQ_W)) abs_0 (.r(bin_real), .i(bin_imag), .a(abs_out));
    reg [FREQ_W-1:0] fbin_real, fbin_imag;

    `ifdef FORMAL // replace multipliers for something else
        // here
    `else
    dsp_mult_16 complex_mult_f1 ( .clock(clk), .A(frequency_bins_real[tw_addr] + delta), .B(twid_real), .X(f1));
    dsp_mult_16 complex_mult_f2 ( .clock(clk), .A(frequency_bins_imag[tw_addr] + 0), .B(twid_imag), .X(f2));
    dsp_mult_16 complex_mult_f3 ( .clock(clk), .A(frequency_bins_real[tw_addr] + delta), .B(twid_imag), .X(f3));
    dsp_mult_16 complex_mult_f4 ( .clock(clk), .A(frequency_bins_imag[tw_addr] + 0), .B(twid_real), .X(f4));
    `endif
    
    always@(posedge clk) begin
        case(state)
            STATE_WAIT: begin
                if(start)
                    state <= STATE_START;
                if(read)
                    state <= STATE_READ;
            end 

            STATE_READ: begin
            // now do the multiplcation to a real number with the dsps
                bin_real <= frequency_bins_real[bin_addr];
                bin_imag <= frequency_bins_imag[bin_addr];
                bin_out <= abs_out;

                if(read)
                    state <= STATE_READ;
                else
                    state <= STATE_WAIT;
            end

            STATE_START: begin
                // get delta: newest - oldest
                delta <= sample - samples[sample_index];
                // store new sample
                samples[sample_index] <= sample;
                tw_addr <= 0;
                state <= STATE_CALC_1;
            end

            STATE_CALC_1: begin
                // wait for f1 - f4 multiplies to finish
                state <= STATE_CALC_2;
            end

            STATE_CALC_2: begin
                // store results

                state <= STATE_CALC_3;

            end

            STATE_CALC_3: begin
                // wait for twid imag and real to load, and new freq bins
                // increment tw_addr

                frequency_bins_real[tw_addr] <= (f1 - f2)  >>> (TWID_W-1); // divide back by 1 less than TWID_W as coefficents are scaled up to fill signed width
                frequency_bins_imag[tw_addr] <= (f3 + f4)  >>> (TWID_W-1);
                fbin_real <= (f1-f2) >>> (TWID_W-1);
                fbin_imag <= (f3+f4) >>> (TWID_W-1);

                tw_addr <= tw_addr + 1; 

                if(tw_addr == LIMIT_BINS -1) begin
                    tw_addr <= 0;
                    state <= STATE_FINISH;
                end else
                    state <= STATE_CALC_1;
            end

            STATE_FINISH: begin
                // increment sample index (same as rotating)
                sample_index <= sample_index + 1;
                // reset index if it wraps
                if(sample_index == FREQ_BINS -1)
                    sample_index <= 0;
                state <= STATE_WAIT;
            end 

        endcase

    end
    `ifdef FORMAL
        always @(posedge clk) begin
            assume(start == 0);
            assert(bin_out == 0);
        end
    `endif

endmodule

