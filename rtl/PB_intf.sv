`default_nettype none

// this module models after the push button interface 
module PB_intf(clk, rst_n, tgglMd, scale, setting);

    // declare input and output signals
    input logic clk, rst_n, tgglMd;
    output logic [2:0] scale;
    output logic [1:0] setting;

    logic released;

    // call the Push button release 
    PB_release PB1(.clk(clk), .rst_n(rst_n), .PB(tgglMd), .released(released));

    // flip flop for the setting, only increment setting if released goes high

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            setting <= 2'b10;
        end else if (released) begin
            setting <= setting + 1;
        end
    end

    // assign scale based on the setting value
    assign scale = (setting == 2'b00) ? 3'b000 :
                  (setting == 2'b01) ? 3'b011 :
                  (setting == 2'b10) ? 3'b101 :
                  (setting == 2'b11) ? 3'b111 : 3'b000;

endmodule
