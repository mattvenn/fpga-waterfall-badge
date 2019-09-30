`default_nettype none
module abs #(
    parameter width = 16
    )
    (
    input signed [width-1:0] r, i,
    output [width-1:0] a
    );

    wire i_pos = i[width-1] == 0;
    wire r_pos = r[width-1] == 0;
    
    assign a = ( i_pos &&  r_pos && i >=  r) ?  i + ( r >>> 1) : // both +ve       i > r
               ( i_pos &&  r_pos && i <   r) ?  r + ( i >>> 1) : // both +ve       r > i
               (~i_pos && ~r_pos && i <=  r) ? -i + (-r >>> 1) : // both -ve       i > r
               (~i_pos && ~r_pos && i >   r) ? -r + (-i >>> 1) : // both -ve       r > i
               ( i_pos && ~r_pos && i >= -r) ?  i + (-r >>> 1) : // i +ve r -ve    i > r
               (~i_pos &&  r_pos && i <  -r) ? -i + ( r >>> 1) : // i +ve r -ve    i < r
               (~i_pos &&  r_pos && i >= -r) ?  r + (-i >>> 1) : //-ve r +ve    i > r
                                              -r + ( i >>> 1);  // i -ve r +ve    i < r
                
endmodule
