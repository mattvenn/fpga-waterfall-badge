`default_nettype none
module video 
#(
    parameter H_VISIBLE = 10'd320,
    parameter V_VISIBLE = 10'd240 
)
(input clk, //19.2MHz pixel clock in
                input resetn,
                input [23:0] rgb_data,
                output visible,
                output lower_blank,
                output [8:0] x,
                output [7:0] y,
                // register all these
                output wire [7:0] phy_lcd_dat,
                output wire phy_lcd_hsync,
                output wire phy_lcd_vsync,
                output wire phy_lcd_den);

				SB_IO #(
					.PIN_TYPE(6'b010100),
					.PULLUP(1'b0),
					.NEG_TRIGGER(1'b0),
					.IO_STANDARD("SB_LVCMOS")
				) iob_lcd_dat [7:0] (
					.PACKAGE_PIN(phy_lcd_dat),
					.CLOCK_ENABLE(1'b1),
					.OUTPUT_CLK(clk),
					.D_OUT_0(lcd_dat)
				);

				SB_IO #(
					.PIN_TYPE(6'b010100),
					.PULLUP(1'b0),
					.NEG_TRIGGER(1'b0),
					.IO_STANDARD("SB_LVCMOS")
				) iob_lcd_hsync (
					.PACKAGE_PIN(phy_lcd_hsync),
					.CLOCK_ENABLE(1'b1),
					.OUTPUT_CLK(clk),
					.D_OUT_0(lcd_hsync)
				);

                // vsync
				SB_IO #(
					.PIN_TYPE(6'b010100),
					.PULLUP(1'b0),
					.NEG_TRIGGER(1'b0),
					.IO_STANDARD("SB_LVCMOS")
				) iob_lcd_vsync (
					.PACKAGE_PIN(phy_lcd_vsync),
					.CLOCK_ENABLE(1'b1),
					.OUTPUT_CLK(clk),
					.D_OUT_0(lcd_vsync)
				);

                // den
				SB_IO #(
					.PIN_TYPE(6'b010100),
					.PULLUP(1'b0),
					.NEG_TRIGGER(1'b0),
					.IO_STANDARD("SB_LVCMOS")
				) iob_lcd_den (
					.PACKAGE_PIN(phy_lcd_den),
					.CLOCK_ENABLE(1'b1),
					.OUTPUT_CLK(clk),
					.D_OUT_0(lcd_den)
				);

wire phy_lcd_den;

reg [7:0] lcd_dat;
reg lcd_hsync;
reg lcd_vsync;
reg lcd_den;

parameter h_front = 10'd20;
parameter h_sync = 10'd30;
parameter h_back = 10'd38;
parameter h_total = H_VISIBLE + h_front + h_sync + h_back;

parameter v_front = 10'd4;
parameter v_sync = 10'd3;
parameter v_back = 10'd15;
parameter v_total = V_VISIBLE + v_front + v_sync + v_back;

wire lower_blank = v_pos > V_VISIBLE;

reg [1:0] channel = 0;
reg [9:0] h_pos = 0;
reg [9:0] v_pos = 0;

wire h_active, v_active;
assign x = visible ? h_pos : 0;
assign y = visible ? v_pos : 0;

always @(posedge clk) 
begin
  if (resetn == 0) begin
    h_pos <= 10'b0;
    v_pos <= 10'b0;

  end else begin
    //Pixel counters
    if (channel == 2) begin
      channel <= 0;
      if (h_pos == h_total - 1) begin
        h_pos <= 0;
        if (v_pos == v_total - 1) begin
          v_pos <= 0;
        end else begin
          v_pos <= v_pos + 1;
        end
      end else begin
        h_pos <= h_pos + 1;
      end
    end else begin
      channel <= channel + 1;
    end
    lcd_den <= !visible;
    lcd_hsync <= !((h_pos >= (H_VISIBLE + h_front)) && (h_pos < (H_VISIBLE + h_front + h_sync)));
    lcd_vsync <= !((v_pos >= (V_VISIBLE + v_front)) && (v_pos < (V_VISIBLE + v_front + v_sync)));
    lcd_dat <= channel == 0 ? rgb_data[23:16] : 
               channel == 1 ? rgb_data[15:8]  :
               rgb_data[7:0];
  end
end

assign h_active = (h_pos < H_VISIBLE);
assign v_active = (v_pos < V_VISIBLE);
assign visible = h_active && v_active;

endmodule
