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
    
    localparam TORQUE_MIN = 12'h380;

    // declare intermediate signals
    // stage 0
    logic [8:0]  s0_incline_lim;
    logic [5:0]  s0_cadence_factor;
    logic [11:0] s0_torque_pos;
    logic        s0_pedaling;
    logic  [2:0] s0_scale;
    // stage 1
    logic [20:0] s1_prod;             
    logic  [5:0] s1_cadence_factor;
    logic  [2:0] s1_scale;
    logic        s1_pedaling;
    // stage 2
    logic [15:0] s2a_hi_prod; 
    logic [10:0] s2a_lo_part;     
    logic  [2:0] s2a_scale;
    logic        s2a_pedaling;
    logic  [5:0] s2a_cadence_factor;
    logic [16:0] s2b_lo_prod;
    logic [15:0] s2b_hi_prod;
    logic [2:0]  s2b_scale;
    logic        s2b_pedaling;
    logic [26:0] s2_prod;
    logic [2:0]  s2_scale;
    logic        s2_pedaling;
    // stage 3
    logic [29:0] s3a_part;
    logic        s3a_scale_b2;
    logic        s3a_pedaling;
    logic [29:0] hi_term;
    logic [29:0] s3_prod;
    logic        s3_pedaling;

    logic [9:0]  incline_sat;
    logic signed [10:0] incline_factor;
    logic [12:0] torque_off;
    // saturating incline signal down
    assign incline_sat =
        (  incline[12] && ~&incline[11:9]) ? 10'b10_0000_0000 :
        (~ incline[12] &&  |incline[11:9]) ? 10'b01_1111_1111 :
                                             incline[9:0];

    // new signal should be incline_sat + 256, signed
    assign incline_factor = {incline_sat[9],incline_sat} + 11'd256;
    assign torque_off     = {1'b0,avg_torque} - {1'b0,TORQUE_MIN};

    // stage 0 flip flop, saturation for incline
    // if cadence > 1 add 32 to it, else just set it to zero
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s0_incline_lim    <= 9'd0;
            s0_cadence_factor <= 6'd0;
            s0_torque_pos     <= 12'd0;
            s0_pedaling       <= 1'b0;
            s0_scale          <= 3'd0;
        end else begin
            s0_incline_lim <= incline_factor[10]           ? 9'd0   :
                              (incline_factor > 9'd511)    ? 9'd511 :
                                                            incline_factor[8:0];

            s0_cadence_factor <= (cadence > 5'd1) ? cadence + 6'd32 : 6'd0;
            s0_torque_pos     <= torque_off[12] ? 12'd0 : torque_off[11:0];
            s0_pedaling       <= ~not_pedaling;
            s0_scale          <=  scale;
        end
    end

    
    // stage 1 flip flop, torque and incline multiply
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_prod            <= 21'd0;
            s1_cadence_factor  <= 6'd0;
            s1_scale           <= 3'd0;
            s1_pedaling        <= 1'b0;
        end else begin
            s1_prod            <= s0_torque_pos * s0_incline_lim; // DSP-1
            s1_cadence_factor  <= s0_cadence_factor;
            s1_scale           <= s0_scale;
            s1_pedaling        <= s0_pedaling;
        end
    end

    // stage 2 flip flop, multiply in cadence factor
    // part a, do the high multiply
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2a_hi_prod        <= 16'd0;
            s2a_lo_part        <= 11'd0;
            s2a_scale          <= 3'd0;
            s2a_pedaling       <= 1'b0;
            s2a_cadence_factor <= 6'd0;
        end else begin
            s2a_hi_prod        <= s1_prod[20:11] * s1_cadence_factor; // DSP-2a
            s2a_lo_part        <= s1_prod[10:0];
            s2a_scale          <= s1_scale;
            s2a_pedaling       <= s1_pedaling;
            s2a_cadence_factor <= s1_cadence_factor;  // forward for next stage
        end
    end

    // Stage 2b: Perform the lower multiply with cadence factor
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2b_lo_prod  <= 17'd0;
            s2b_hi_prod  <= 16'd0;
            s2b_scale    <= 3'd0;
            s2b_pedaling <= 1'b0;
        end else begin
            s2b_lo_prod  <= s2a_lo_part * s2a_cadence_factor;
            s2b_hi_prod  <= s2a_hi_prod;
            s2b_scale    <= s2a_scale;
            s2b_pedaling <= s2a_pedaling;
        end
    end

    // stage 2c: combine the high and low parts
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_prod     <= 27'd0;
            s2_scale    <= 3'd0;
            s2_pedaling <= 1'b0;
        end else begin
            // Add the results from the previous values
            s2_prod <= {s2b_hi_prod, 11'd0} + {10'd0, s2b_lo_prod};
            s2_scale    <= s2b_scale;
            s2_pedaling <= s2b_pedaling;
        end
    end

    // stage 3a: multiply by scale
    // the idea is to multiply by 2^0, 2^1, and 2^2 based on each bit of scale
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s3a_part     <= 30'd0;
            s3a_scale_b2 <= 1'b0;
            s3a_pedaling <= 1'b0;
        end else begin
            s3a_part <= (s2_scale[0] ?                s2_prod        : 30'd0) +
                         (s2_scale[1] ? (s2_prod << 1)              : 30'd0);
            s3a_scale_b2 <= s2_scale[2];
            s3a_pedaling <= s2_pedaling;
            hi_term = s3a_scale_b2 ? (s2_prod << 2) : 30'd0;
        end
    end

    // stage 3b: add the high term to the partial product
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s3_prod     <= 30'd0;
            s3_pedaling <= 1'b0;
        end else begin
            
            s3_prod     <= s3a_part + hi_term;
            s3_pedaling <= s3a_pedaling;
        end
    end

    // stage 4: determine target current by grabbing bits from prod
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            target_curr <= 12'd0;
        else if (!s3_pedaling)
            target_curr <= 12'd0;
        else if (|s3_prod[29:27])
            target_curr <= 12'hFFF;
        else
            target_curr <= s3_prod[26:15];
    end
endmodule

