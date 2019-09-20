`default_nettype none
module top(
    input clock_in,
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

wire pixclk;
wire locked;
wire visible;
wire adc_ready;
wire start;
reg [23:0] rgb_data;
localparam SAMPLE_WIDTH = 12;  // sample bit depth - actually ADC is only 12 bit
wire [SAMPLE_WIDTH-1:0] adc_data;

pll pll_i(.clock_in(clock_in), .clock_out(pixclk), .locked(locked));

adc adc_inst_0(.clk(pixclk), .reset(0), .adc_clk(adc_clk), .adc_cs(adc_cs), .adc_sd(adc_sd), .ready(adc_ready), .data(adc_data));

lcdtest lcddrv_i (.clk(pixclk), //20.2MHz pixel clock in
                  .visible(visible),
                  .start(start),
                  .resetn(locked),
                  .lcd_dat(lcd_dat),
                  .lcd_hsync(lcd_hsync),
                  .lcd_hsync(lcd_hsync),
                  .rgb_data(rgb_data),
                  .lcd_den(lcd_den));

//assign LED2 = locked; // yosys reports this error when uncommented: ERROR: Mismatch in directionality for cell port top.pll_i.locked: \locked <= \pll_i.locked
always @(posedge pixclk)
    if(start)
        rgb_data <= {adc_data[11:4], 8'b0, adc_data[11:4]};

assign LEDR_N = adc_data[SAMPLE_WIDTH-1];
assign LEDG_N = adc_data[SAMPLE_WIDTH-2];
  
assign lcd_clk = pixclk;

assign lcd_reset = 1'b1;
  
endmodule
