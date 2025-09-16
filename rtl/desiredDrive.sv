`default_nettype none
// this module implements desired drive
module desiredDrive(clk, rst_n, avg_torque, cadence, not_pedaling, incline, scale, target_curr);
    // declare input and output signals
    input logic clk, rst_n;
    input logic [11:0] avg_torque;
    input logic [4:0] cadence;
    input logic [12:0] incline;
    input logic [2:0] scale;
    input logic not_pedaling;
    output logic [11:0] target_curr;

    // declare intermediate signals
    logic[9:0] incline_sat;
    logic signed [10:0] incline_factor;
    logic[12:0] torque_off;
   
    localparam TORQUE_MIN = 12'h380;

    // signals for pipelining
    // stage 0 signals
    logic [8:0]  s0_incline_lim;
    logic [5:0]  s0_cadence_factor;
    logic [11:0] s0_torque_pos;
    logic        s0_pedaling;
    logic  [2:0] s0_scale;
    // stage 1 signals
    logic [20:0] s1_partial_prod;
    logic [5:0]  s1_cadence_factor;
    logic  [2:0] s1_scale;
    logic        s1_pedaling;
    // stage 2 signals
    logic [26:0] s2_assist_prod;
    logic  [2:0] s2_scale;
    logic        s2_pedaling;
    // stage 3 signals
    logic [29:0] s3_prod;

    // saturating signal down
    assign incline_sat = (incline[12] && (~&incline[11:9])) ? 10'b10_0000_0000 :
                        (~incline[12] && (|incline[11:9])) ? 10'b01_1111_1111 :
                        incline[9:0];
    // new signal should be incline_sat + 256, signed
    assign incline_factor = {incline_sat[9], incline_sat} + 11'd256;
    // sign extend both avg_torque and TORQUE_MIN so that it can result in a neg number
    // so we zero extend the two signals
    assign torque_off = {1'b0, avg_torque} - {1'b0, TORQUE_MIN};

    // stage 0 flip flop, saturation for incline
    // if cadence > 1 add 32 to it, else just set it to zero
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            s0_incline_lim <= 9'd0;
            s0_cadence_factor <= 6'd0;
            s0_torque_pos <= 12'd0;
            s0_pedaling <= 1'b0;
            s0_scale <= 3'd0;
        end else begin
            // saturation for incline
            s0_incline_lim <= (incline_factor[10]) ? 9'h000 :
                        (incline_factor > 9'd511) ? 9'd511 :
                         incline_factor[8:0];

            s0_cadence_factor <= (cadence > 5'd1) ? cadence + 6'd32 :
                            6'h00;

            // if torque off is negative set it to zero otherwise set it to the lower N-1 bits of torque off
            s0_torque_pos <= (torque_off[12]) ? 11'd0 : torque_off[11:0];

            s0_pedaling <= ~not_pedaling;
            s0_scale    <=  scale;
        end
    end

    // stage 1 flip flop, torque and incline multiply
    // for most signals, we just pass them through
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_partial_prod   <= 21'd0;
            s1_cadence_factor <=  6'd0;
            s1_scale          <=  3'd0;
            s1_pedaling       <=  1'b0;
        end
        else begin
            s1_partial_prod   <= s0_torque_pos * s0_incline_lim;
            s1_cadence_factor <= s0_cadence_factor;
            s1_scale          <= s0_scale;
            s1_pedaling       <= s0_pedaling;
        end
    end

    // stage 2 flip flop, cadence multiply
     always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_assist_prod <= 27'd0;
            s2_pedaling <= 1'b0;
            s2_scale <= 3'd0;
        end
        else begin
            s2_assist_prod  <= s1_partial_prod * s1_cadence_factor;
            s2_pedaling <= s1_pedaling;
            s2_scale <= s1_scale;
        end
    end

    // stage 3 flip flop, multiply in scale
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            s3_prod <= 30'd0;
        else
            s3_prod <= s2_assist_prod * s2_scale;
    end

    // assign target curr by saturating s3_prod
    // also not pedaling check
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            target_curr <= 12'd0;
        else if (!s2_pedaling)
            target_curr <= 12'd0;
        else if (|s3_prod[29:27])
            target_curr <= 12'hFFF;
        else
            target_curr <= s3_prod[26:15];
    end
endmodule