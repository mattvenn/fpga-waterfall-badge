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
                output reg [7:0] lcd_dat,
                output reg lcd_hsync,
                output reg lcd_vsync,
                output reg lcd_den);
              
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
