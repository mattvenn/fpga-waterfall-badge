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
localparam SAMPLE_WIDTH = 12;   // sample bit depth - actually ADC is only 12 bit
wire [SAMPLE_WIDTH-1:0] adc_data;
wire adc_ready;
reg [7:0] adc_buf;              // buffer a single read so it doesn't change while using it

// frame buffer reg/wires
reg frame_buf_wenable = 0;      // ram write enable
reg [7:0] frame_buf_wdata;      // data to write to frame buffer
wire [7:0] frame_buf_rdata;     // data coming from frame buffer
reg [16:0] frame_buf_addr = 0;

// scrolling frame buffer 
reg [7:0] y_offset = 0;         // which line is currently being used as the 1st line, max 240
reg [7:0] y_offset_mod = 0;     // (y_offset + y) mod 240, max 240
reg [1:0] scroll_delay = 0;     // used to count frames till next scroll, 2 bit counter so 4 times slower than frame rate
reg [8:0] x_count = 0;          // counter for copying adc data into frame buffer

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

// state machine
localparam STATE_RESET      = 1;
localparam STATE_VIDEO      = 2;
localparam STATE_WRITE_RAM  = 3;
localparam STATE_WAIT_VIDEO = 4;
localparam STATE_END        = 5;

reg [$clog2(STATE_END)-1:0] state = STATE_RESET;

always @(posedge pixclk) begin
    case(state)
        // write zeros to all of frame buffer
        STATE_RESET: begin
            frame_buf_addr <= frame_buf_addr + 1;
            frame_buf_wdata <= 0;
            frame_buf_wenable <= 1;
            if(frame_buf_addr == 320 * 240) begin
                state <= STATE_VIDEO;
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
                    state <= STATE_WRITE_RAM;
                    adc_buf <= adc_data[11:4];
                    x_count <= 0;
                    frame_buf_wenable <= 1;
                end
            end
        end

        // grab ADC data and use it to draw a line at the top of the screen
        STATE_WRITE_RAM: begin
            x_count <= x_count + 1;
            frame_buf_addr <= x_count + (((y_offset << 2 ) + y_offset)<<6);
            frame_buf_wdata <= x_count > adc_buf ? adc_buf : 8'h00;
            
            if( x_count == 320) begin
                frame_buf_wenable <= 0;
                state <= STATE_WAIT_VIDEO;

                y_offset <= y_offset + 1; // scroll 1 more line
                if(y_offset == 240)
                    y_offset <= 0;
            end
        end

        STATE_WAIT_VIDEO: begin
            if(~lower_blank)
                state <= STATE_VIDEO;
        end

    endcase

end
  
endmodule
