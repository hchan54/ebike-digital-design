/**
Group: Timing Violators
Members: Eddie Lin, Paul Avioli, Jake Yun, Hunter Chan
*/
`default_nettype none
module PID(clk, rst_n, drv_mag, error, not_pedaling);

    input logic clk, rst_n, not_pedaling;
    input logic signed [12:0] error;
    output logic [11:0] drv_mag;
    parameter FAST_SIM = 0;

    /// clock logic
    logic [19:0] cnt;
    logic        cnt_full;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 20'd0;
        else
            cnt <= cnt + 1;
    end

    generate
        if (FAST_SIM)
            assign cnt_full = &cnt[14:0];
        else
            assign cnt_full = &cnt;
    endgenerate

    // I/P-term logic
    // Sign-extend the error to 18 bits
    logic signed [17:0] error18;
    // 'integrator' is the running accumulator; it gets updated on cnt_full
    logic signed [17:0] integrator, integratorFlopin;
    // P_term is the 14-bit sign-extended error
    logic signed [13:0] P_term;
    // I_term is taken from bits [16:5] of the integrator register
    logic [11:0] I_term;

    always_comb begin
        // Sign extend error to 18 bits
        error18 = {{5{error[12]}}, error};
        // Use the lower 14 bits of error18 for the P term
        P_term = error18[13:0];

        // Update integrator only on the decimation tick (cnt_full)
        if (cnt_full) begin
            if (not_pedaling) begin
                integratorFlopin = 18'sd0;  // Reset integrator when not pedaling
            end else begin
                // Calculate new integrator sum
                logic signed [17:0] sum_i;
                sum_i = integrator + error18;
                // Clear if sum is negative
                if (sum_i < 0)
                    integratorFlopin = 18'sd0;
                // Saturate if sum exceeds maximum (18'h1FFFF)
                else if (sum_i > 18'h1FFFF)
                    integratorFlopin = 18'h1FFFF;
                else
                    integratorFlopin = sum_i;
            end
        end else begin
            integratorFlopin = integrator;  // Hold value if tick is not active
        end

        // I_term is defined as the upper 12 bits (from bit 16 downto 5) of the integrator register
        I_term = integrator[16:5];
    end

    // Update the integrator register on the decimation tick
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            integrator <= 18'sd0;
        else if (cnt_full)
            integrator <= integratorFlopin;
    end

    //D-term
    // Create a three-stage delay for error samples
    logic signed [12:0] error_d1, error_d2, error_d3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_d1 <= 13'sd0;
            error_d2 <= 13'sd0;
            error_d3 <= 13'sd0;
        end else if (cnt_full) begin
            error_d1 <= error;
            error_d2 <= error_d1;
            error_d3 <= error_d2;
        end
    end

    // Compute the derivative difference using the current error and the oldest delayed error
    logic signed [13:0] D_diff;
    assign D_diff = error - error_d3;

    // Saturate the derivative difference to 9 bits.
    // For a 9-bit signed number, the range is -128 to 127.
    localparam signed [8:0] D_SAT_MAX = 9'sd127;
    localparam signed [8:0] D_SAT_MIN = -9'sd128;
    logic signed [8:0] D_sat;

    always_comb begin
        if (D_diff > D_SAT_MAX)
            D_sat = D_SAT_MAX;
        else if (D_diff < D_SAT_MIN)
            D_sat = D_SAT_MIN;
        else
            D_sat = D_diff[8:0];
    end

    // Scale (multiply by 2) by shifting left one bit
    logic signed [9:0] D_term;
    assign D_term = {D_sat, 1'b0};

    // PID_output
    logic signed [13:0] PID;
    // Extend I_term and D_term to 14 bits for the summation
    logic signed [13:0] I_extend, D_extend;
    logic        [11:0] PID_mux1;

    always_comb begin
        I_extend = {2'b00, I_term};
        D_extend = {{4{D_term[9]}}, D_term};
        PID = P_term + I_extend + D_extend;

        // If PID result is negative or too high, saturate to 0 or maximum, respectively.
        PID_mux1 = (PID[12]) ? 12'hFFF : PID[11:0];
        drv_mag  = (PID[13]) ? 12'h000 : PID_mux1;
    end

endmodule