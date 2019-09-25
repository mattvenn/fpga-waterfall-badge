`default_nettype none
module top(
    input clock_in,
    input BTN_N,
    output LEDR_N, LEDG_N,
    output lcd_clk,
    output [7:0] lcd_dat,
    output lcd_hsync,
    output lcd_vsync,
    output lcd_den,
    output lcd_reset,

    output adc_clk,
    output adc_cs,
    input wire adc_sd
    
    );

localparam SAMPLE_WIDTH = 12;   // ADC sample bit depth - actually ADC is only 12 bit
localparam FREQ_BINS = 16;       // number of frequency bins - must update twiddle rom if changed
localparam ADDR_W = 9;          // number of address lines needed for freq bins
localparam DATA_W = 8;          // dft internal data width


// lcd wires
wire pixclk;
wire locked;
wire visible;
wire lower_blank;
wire [8:0] x;
wire [7:0] y;
assign lcd_clk = pixclk;
assign lcd_reset = 1'b1;

wire [23:0] rgb_data;           // used to send serial RGB data to the video module
wire [23:0] rgb_data_gradient;  // data coming out of the gradient lookup ROM

// blank first 2 pixels of each row because the address lookup takes 2 clocks
assign rgb_data = x < 2 ? 24'b0 : rgb_data_gradient;

// adc
wire [SAMPLE_WIDTH-1:0] adc_data;
wire adc_ready;

// frame buffer reg/wires
reg frame_buf_wenable = 0;      // ram write enable
reg [7:0] frame_buf_wdata;      // data to write to frame buffer
wire [7:0] frame_buf_rdata;     // data coming from frame buffer
reg [16:0] frame_buf_addr = 0;

// scrolling frame buffer 
reg [7:0] y_offset = 0;         // which line is currently being used as the 1st line, max 240
reg [7:0] y_offset_mod = 0;     // (y_offset + y) mod 240, max 240
reg  scroll_delay = 0;          // used to count frames till next scroll, 2 bit counter so 4 times slower than frame rate

// frequency bin bram
reg  [8:0] freq_bram_waddr = 0;
reg  [7:0] freq_bram_wdata = 0;
reg  [8:0] freq_bram_bin = 0;
wire [7:0] freq_bram_rdata;
reg freq_bram_w = 0; // write enable signal
reg freq_bram_r = 0; // read enable signal

// dft
reg fft_start = 0;
reg fft_read = 0;
reg [7:0] fft_sample = 0;
wire fft_ready;
wire [15:0] bin_out;

// buttons
assign LEDR_N = BTN_N;
assign LEDG_N = adc_data[SAMPLE_WIDTH-2];
  
// modules

// gradientROM is a 256x24b lookup that stores the gradient colour. This means the frame buffer just has to store single 8b values for each pixel
gradientROM gradientROM_0 (.clk(pixclk), .addr(frame_buf_rdata), .dout(rgb_data_gradient));

// PLL for the video
pll pll_0(.clock_in(clock_in), .clock_out(pixclk), .locked(locked));

// serial ADC. 12b at up to 3MHz
adc adc_inst_0(.clk(pixclk), .reset(1'b0), .adc_clk(adc_clk), .adc_cs(adc_cs), .adc_sd(adc_sd), .ready(adc_ready), .data(adc_data));

// frame buffer
ram frame_buffer_0 (.clk(pixclk), .addr(frame_buf_addr), .wdata(frame_buf_wdata), .rdata(frame_buf_rdata), .w_enable(frame_buf_wenable));

// dual ported bram between fft and video
freq_bram #(.addr_w(ADDR_W), .data_w(DATA_W)) freq_bram_0(.w_clk(pixclk), .r_clk(pixclk), .w_en(freq_bram_w), .r_en(freq_bram_r), .d_in(freq_bram_wdata), .d_out(freq_bram_rdata), .r_addr(freq_bram_bin), .w_addr(freq_bram_waddr));

// lcd driver
video video_0 (.clk(pixclk), //20.2MHz pixel clock in
                  .visible(visible),
                  .lower_blank(lower_blank),
                  .resetn(locked),
                  .lcd_dat(lcd_dat),
                  .lcd_hsync(lcd_hsync),
                  .lcd_vsync(lcd_vsync),
                  .rgb_data(rgb_data),
                  .x(x),
                  .y(y),
                  .lcd_den(lcd_den));

// sliding dft
sdft #(.data_w(DATA_W), .freq_bins(FREQ_BINS), .freq_w(DATA_W*2)) sdft_0(.clk (pixclk), .sample(fft_sample), .ready(fft_ready), .start(fft_start), .read(fft_read), .bin_out(bin_out), .bin_addr(freq_bram_waddr)); 

// state machine for scrolling pixel buffer
localparam STATE_RESET      = 1;
localparam STATE_VIDEO      = 2;
localparam STATE_WRITE_RAM  = 3;
localparam STATE_WAIT_VIDEO = 4;
localparam STATE_END        = 5;

reg [$clog2(STATE_END)-1:0] pix_state = STATE_RESET;

always @(posedge pixclk) begin
    case(pix_state)
        // write zeros to all of frame buffer
        STATE_RESET: begin
            frame_buf_addr <= frame_buf_addr + 1;
            frame_buf_wdata <= 0;
            frame_buf_wenable <= 1;
            if(frame_buf_addr == 320 * 240) begin
                pix_state <= STATE_VIDEO;
                frame_buf_wenable <= 0;
            end

        end

        // read pixel from ram until get to lower blanking. 
        STATE_VIDEO: begin
            y_offset_mod <= (y + y_offset) >= 240 ? y + y_offset - 240 : y+y_offset;
            frame_buf_addr <= x + (((y_offset_mod << 2) + y_offset_mod)<<6); // optimisation for y * 320
            if(lower_blank) begin
                scroll_delay <= scroll_delay + 1;
                if(&scroll_delay) begin
                    pix_state <= STATE_WRITE_RAM;
                    freq_bram_bin <= 0;
                    freq_bram_r <= 1;
                    frame_buf_wenable <= 1;
                end else
                    pix_state <= STATE_WAIT_VIDEO;
            end
        end

        // grab fft data and use it to draw a line in the frame buffer, y position changes every cycle to make a scrolling effect
        STATE_WRITE_RAM: begin
            freq_bram_bin <= freq_bram_bin + 1;
            frame_buf_addr <= freq_bram_bin + (((y_offset << 2 ) + y_offset)<<6);
            frame_buf_wdata <= freq_bram_rdata;
            
            if(freq_bram_bin == FREQ_BINS) begin
                frame_buf_wenable <= 0;
                freq_bram_r <= 0;
                pix_state <= STATE_WAIT_VIDEO;

                y_offset <= y_offset + 1; // scroll 1 more line
                if(y_offset == 240)
                    y_offset <= 0;
            end
        end

        STATE_WAIT_VIDEO: begin
            if(~lower_blank)
                pix_state <= STATE_VIDEO;
        end

    endcase

end

localparam STATE_FFT_WAIT = 0;
localparam STATE_FFT_WAIT_START = 1;
localparam STATE_FFT_PROCESS = 2;
localparam STATE_FFT_READ = 3;

reg [3:0] fft_state = STATE_FFT_WAIT;
// sample data as fast as possible
always @(posedge pixclk) begin
    case(fft_state)
        STATE_FFT_WAIT: begin
            if(fft_ready) begin
                fft_sample <= adc_data[11:3];
                fft_start <= 1'b1;
                fft_state <= STATE_FFT_WAIT_START;
            end
        end

        STATE_FFT_WAIT_START: begin
            if(fft_ready == 0)
                fft_state <= STATE_FFT_PROCESS;
        end

        STATE_FFT_PROCESS: begin
            fft_start <= 1'b0;
            if(fft_ready) begin
                fft_read <= 1'b1;
                freq_bram_w <= 1'b1;
                fft_state <= STATE_FFT_READ;
            end
        end

        STATE_FFT_READ: begin
            // store all the squared bin values to BRAM
            freq_bram_wdata <= bin_out;
            freq_bram_waddr <= freq_bram_waddr + 1;
            if(freq_bram_waddr == 320) begin
                freq_bram_waddr <= 0;
                freq_bram_w <= 1'b0;
                fft_read <= 1'b0;
                fft_state <= STATE_FFT_WAIT;
            end
        end

    endcase
end
  
endmodule
