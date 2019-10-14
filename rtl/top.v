`default_nettype none
module top 
    #(
    parameter GRADIENT_FILE = "GRADIENT_PURPLE_BLUE_WHITE.hex",
    parameter SAMPLE_WIDTH = 12,    // ADC sample bit depth - actually ADC is only 12 bit
    parameter FREQ_BINS = 640,      // number of frequency bins - must update twiddle rom if changed
    parameter LIMIT_BINS = 320,     // only calculate first 320 bins
    parameter ADDR_W = 9,           // number of address lines needed for freq bins
    parameter DATA_W = 8,           // dft internal data width
    parameter H_VISIBLE = 10'd320,
    parameter V_VISIBLE = 10'd240 
    )
    (
    input clock_in,
    input BTN_N,
    output LEDR_N, LEDG_N,
    output P2_1,
    output LED_BLU_N,
    output LED_RED_N,
    output LED_GRN_N,
    output lcd_clk,
    output [7:0] lcd_dat,
    output lcd_hsync,
    output lcd_vsync,
    output lcd_den,
    output lcd_reset,
/*
    output adc_clk,
    output adc_cs,
    input wire adc_sd,
    */

    output adc_mic_cs,
    input adc_mic_sd,
    output adc_mic_clk

    
    );

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

// adc mic
wire [SAMPLE_WIDTH-1:0] adc_data;

// LEDs are a crude level indicator
assign LEDG_N = ~(adc_data > (1 << 7));
assign LEDR_N = ~(adc_data > (1 << 9));

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

reg [20:0] slow_count = 0;
assign LED_RED_N = slow_count[20];
assign LED_GRN_N = ~slow_count[20];
always @(posedge pixclk)
    slow_count <= slow_count + 1;

// modules

// gradientROM is a 256x24b lookup that stores the gradient colour. This means the frame buffer just has to store single 8b values for each pixel
gradientROM #(.GRADIENT_FILE(GRADIENT_FILE)) gradientROM_0 (.clk(pixclk), .addr(frame_buf_rdata), .dout(rgb_data_gradient));

// PLL for the video
pll pll_0(.clock_in(clock_in), .clock_out(pixclk), .locked(locked));

// serial ADC 12b at 1MSPS, run at 10 times slower than clock
smpladc #(.CKPCK(10)) adc_mic_0 (.i_clk(pixclk), .i_request(1'b1), .i_rd(1'b0), .i_en(1'b1), .o_csn(adc_mic_cs), .o_sck(adc_mic_clk), .i_miso(adc_mic_sd), .o_data(adc_data));

// frame buffer
ram frame_buffer_0 (.clk(pixclk), .addr(frame_buf_addr), .wdata(frame_buf_wdata), .rdata(frame_buf_rdata), .w_enable(frame_buf_wenable));

// dual ported bram between fft and video
freq_bram #(.addr_w(ADDR_W), .data_w(DATA_W)) freq_bram_0(.w_clk(pixclk), .r_clk(pixclk), .w_en(freq_bram_w), .r_en(freq_bram_r), .d_in(freq_bram_wdata), .d_out(freq_bram_rdata), .r_addr(freq_bram_bin), .w_addr(freq_bram_waddr));

// lcd driver
video #(.H_VISIBLE(H_VISIBLE), .V_VISIBLE(V_VISIBLE)) video_0 (.clk(pixclk), //20.2MHz pixel clock in
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
sdft #(.DATA_W(DATA_W), .FREQ_BINS(FREQ_BINS), .LIMIT_BINS(LIMIT_BINS), .FREQ_W(DATA_W*2)) sdft_0(.clk (pixclk), .sample(fft_sample), .ready(fft_ready), .start(fft_start), .read(fft_read), .bin_out(bin_out), .bin_addr(freq_bram_waddr)); 

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
            if(frame_buf_addr == H_VISIBLE * V_VISIBLE) begin
                pix_state <= STATE_VIDEO;
                frame_buf_wenable <= 0;
            end

        end

        // read pixel from ram until get to lower blanking. 
        STATE_VIDEO: begin
            y_offset_mod <= (y + y_offset) >= V_VISIBLE ? y + y_offset - V_VISIBLE : y+y_offset;
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
            
            if(freq_bram_bin == LIMIT_BINS) begin
                frame_buf_wenable <= 0;
                freq_bram_r <= 0;
                pix_state <= STATE_WAIT_VIDEO;

                y_offset <= y_offset + 1; // scroll 1 more line
                if(y_offset == V_VISIBLE)
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
localparam STATE_FFT_READ_WAIT = 4;
assign P2_1 = fft_start;
reg [3:0] fft_state = STATE_FFT_WAIT;
// sample data as fast as possible
always @(posedge pixclk) begin
    case(fft_state)
        STATE_FFT_WAIT: begin
            if(fft_ready) begin
                fft_sample <= adc_data[8:1];
//                fft_sample <= adc_data[11:4];
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
                freq_bram_w <= 1'b1;
                fft_read <= 1'b1;
                fft_state <= STATE_FFT_READ;
                freq_bram_waddr <= freq_bram_waddr + 1;
            end
        end

        STATE_FFT_READ: begin
            freq_bram_w <= 1'b0;
            fft_read <= 1'b0;
            freq_bram_wdata <= bin_out;
            if(freq_bram_waddr == LIMIT_BINS) begin
                freq_bram_waddr <= 0;
            end
            fft_state <= STATE_FFT_WAIT;
        end

    endcase
end
  
endmodule
