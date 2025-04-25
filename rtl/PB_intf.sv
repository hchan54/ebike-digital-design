`default_nettype none
module PB_intf(clk, rst_n, tgglMd, scale, setting);

    input logic clk, rst_n, tgglMd;
    output logic [2:0] scale;

    logic released;
    output logic [1:0] setting;

    PB_release PB1(.clk(clk), .rst_n(rst_n), .PB(tgglMd), .released(released));

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            setting <= 2'b10;
        end else if (released) begin
            setting <= setting + 1;
        end
    end

    assign scale = (setting == 2'b00) ? 3'b000 :
                  (setting == 2'b01) ? 3'b011 :
                  (setting == 2'b10) ? 3'b101 :
                  (setting == 2'b11) ? 3'b111 : 3'b000;

endmodule
