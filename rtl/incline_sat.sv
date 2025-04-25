`default_nettype none

module incline_sat(incline, incline_sat);
    input logic [12:0] incline;
    output logic[9:0] incline_sat;

    // |incline[11:9] performs a reduction OR operation in verilog, it performs a bitwise or across all bits in the range [11:9]
    // if bit 12 was 1 and bits 11:9 contains a 0 set it to the lowest number possible
    // if bit 12 was 0 and bits [11:9] contain a 1 set it to the highest number possible
    // else just use the least significant 10 bits in the original signal
    assign incline_sat = (incline[12] && (~&incline[11:9])) ? 10'b10_0000_0000 :
                        (~incline[12] && (|incline[11:9])) ? 10'b01_1111_1111 :
                        incline[9:0];
    
endmodule
