/*
model of the ADC that the adc.v core reads
Serial ADC [ADS7883](http://www.ti.com/lit/ds/symlink/ads7883.pdf)
*/
`default_nettype none
module adc_model #(
   parameter WIDTH = 12,
   parameter PERIOD = 10
)
(
    input wire clk,
    input wire cs,
    input wire run,
    output done,
    output reg sd
);

    localparam HIGH = 200;
    localparam LOW  = 0;
    reg [$clog2(WIDTH)-1:0] bit_count = 0;
    reg [WIDTH-1:0] sample_data = HIGH;
    reg [WIDTH-1:0] cycle_timer = 0;

    initial begin
        sd <= 0;
        bit_count <= 0;
    end

    reg cs_int = 0;
    
    always @(*)
        if(cs)
            cs_int <= cs;
        else if(~cs && ~clk)
            cs_int <= 0;
        
    always @(negedge clk) begin
        cycle_timer <= cycle_timer + 1;
        if(cycle_timer == PERIOD) begin
            cycle_timer <= 0;
            if(sample_data == HIGH)
                sample_data <= LOW;
            else
                sample_data <= HIGH;
        end
        if(run) begin
            if(cs_int == 1) begin // reset counters
//                $display("sample = %d", sample_data[sample_count]);
                bit_count <= 0;
                sd <= 0;
            end else if (bit_count <= WIDTH ) begin // clock out data on negedge of clock until end of the sample file
                bit_count <= bit_count + 1;
                if(bit_count == 0) // ADC outputs a leading 0 before the sample data follows
                    sd <= 0;
                else
                    sd <= sample_data[WIDTH-bit_count];
            end
        end else begin
            sd <= 0;
            bit_count <= 0;
        end
    end

endmodule
