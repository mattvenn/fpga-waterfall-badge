`default_nettype none
module sdft
#(
    parameter data_w = 8, 
    parameter freq_bins = 320, // 320
    parameter freq_w    = 16,
    parameter FILE_REAL = "twiddle_real.list",
    parameter FILE_IMAJ = "twiddle_imag.list"
)
(
    input wire                              clk,
    input wire [data_w-1:0]                 sample,
    input wire                              start,
    input wire                              read,
    input wire [bin_addr_w-1:0]             bin_addr,

    output reg [freq_w-1:0]                 bin_out,
    output wire                             ready
);

    // width of addr needed to address the frequency bins
    localparam bin_addr_w = $clog2(freq_bins);

    // register for the twiddle factor ROM
    reg [bin_addr_w-1:0] tw_addr;

    // register for sample index
    reg [bin_addr_w-1:0] sample_index;

    // twiddle factor ROM
    wire signed [data_w-1:0] twid_real;
    wire signed [data_w-1:0] twid_imag;
    twiddle_rom #(.addr_w(bin_addr_w), .data_w(data_w)) twiddle_rom_0(.clk(clk), .addr(tw_addr), .dout_real(twid_real), .dout_imag(twid_imag));

    // frequency bins RAM - double width + 2 to handle multiply
    reg signed [freq_w-1:0] frequency_bins_real [freq_bins-1:0];
    reg signed [freq_w-1:0] frequency_bins_imag [freq_bins-1:0];

    // sample storage
    reg [data_w-1:0] samples [freq_bins-1:0];

    // delta storage (1 more than data_width to handle subtraction)
    reg signed [data_w:0] delta;

    integer j;
    initial begin
        `ifdef DEBUG
        tw_addr = 0; // can't have initial begin or BRAM won't infer
        sample_index = 0;
        delta = 0;
        for(j = 0; j < freq_bins; j = j + 1)  begin
            samples[j] <= 0;
            frequency_bins_real[j] <= 0;
            frequency_bins_imag[j] <= 0;
        end
        `endif
        
    end

    localparam STATE_WAIT           = 0;
    localparam STATE_START          = 1;
    localparam STATE_READ           = 2;
    localparam STATE_LOAD_ROM       = 3;
    localparam STATE_WAIT_ROM       = 4;
    localparam STATE_CALC           = 5;
    localparam STATE_FINISH         = 6;

    reg [3:0] state = STATE_WAIT;

    assign ready = (state == STATE_WAIT) ? 1'b1 : 1'b0;

    reg [freq_w-1:0] bin_real, bin_imag;

    // square the imaginary output to get something real
    dsp_mult_16 out_mult_real ( .clock(clk), .A(bin_real), .B(bin_real), .X(out_real_sq));
    dsp_mult_16 out_mult_imag ( .clock(clk), .A(bin_imag), .B(bin_imag), .X(out_imag_sq));
    wire [31:0] out_real_sq, out_imag_sq;
    wire [31:0] f1, f2, f3, f4;

    dsp_mult_16 complex_mult_f1 ( .clock(clk), .A(frequency_bins_real[tw_addr] + delta), .B(twid_real), .X(f1));
    dsp_mult_16 complex_mult_f2 ( .clock(clk), .A(frequency_bins_imag[tw_addr] + delta), .B(twid_imag), .X(f2));
    dsp_mult_16 complex_mult_f3 ( .clock(clk), .A(frequency_bins_real[tw_addr] + delta), .B(twid_imag), .X(f3));
    dsp_mult_16 complex_mult_f4 ( .clock(clk), .A(frequency_bins_imag[tw_addr] + delta), .B(twid_real), .X(f4));
    
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
            //    bin_out_real <= frequency_bins_real[bin_addr];
            //    bin_out_imag <= frequency_bins_imag[bin_addr];
                bin_imag <= frequency_bins_imag[bin_addr];
                bin_real <= frequency_bins_real[bin_addr];
                bin_out = (out_real_sq + out_imag_sq ) >>> 8;
                state <= STATE_WAIT;

            end

            STATE_START: begin
                // get delta: newest - oldest
                delta <= sample - samples[sample_index];
                // store new sample
                samples[sample_index] <= sample;
                tw_addr <= 0;
                state <= STATE_CALC;
            end

            STATE_LOAD_ROM: begin // 2
                tw_addr <= tw_addr + 1; 
                if(tw_addr == freq_bins -1) begin
                    tw_addr <= 0;
                    state <= STATE_FINISH;
                end else
                    state <= STATE_WAIT_ROM;
            end

            STATE_WAIT_ROM: begin // 3
                state <= STATE_CALC;
            end

            STATE_CALC: begin // 4
                frequency_bins_real[tw_addr] <= (f1 - f2) >>> 7;
                frequency_bins_imag[tw_addr] <= (f3 + f4) >>> 7;
//                frequency_bins_real[tw_addr] <= ((frequency_bins_real[tw_addr] + delta) * twid_real - (frequency_bins_imag[tw_addr] * twid_imag)) >>> 7;
//                frequency_bins_imag[tw_addr] <= ((frequency_bins_real[tw_addr] + delta) * twid_imag + (frequency_bins_imag[tw_addr] * twid_real)) >>> 7;
                state <= STATE_LOAD_ROM;
            end

            STATE_FINISH: begin
                // increment sample index (same as rotating)
                sample_index <= sample_index + 1;
                // reset index if it wraps
                if(sample_index == freq_bins -1)
                    sample_index <= 0;
                state <= STATE_WAIT;
            end 

        endcase
    end


endmodule

